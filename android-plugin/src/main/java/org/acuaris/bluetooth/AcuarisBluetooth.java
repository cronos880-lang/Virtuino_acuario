package org.acuaris.bluetooth;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Bluetooth clásico, perfil puerto serie (SPP), para módulos HC-05 / HC-06.
 *
 * Métodos para GDScript: tiene_permisos, solicitar_permisos, bluetooth_activo,
 * dispositivos_emparejados (JSON), conectar(direccion), enviar(texto), desconectar.
 * Señales: bt_datos(texto), bt_estado(estado, detalle), bt_permisos(concedidos).
 * Estados: "conectando", "conectado", "desconectado", "error".
 */
public class AcuarisBluetooth extends GodotPlugin {
    private static final String TAG = "AcuarisBluetooth";
    private static final UUID SPP = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
    private static final int PETICION_PERMISOS = 7301;

    private final ExecutorService escritor = Executors.newSingleThreadExecutor();
    private final Object cerrojo = new Object();
    private BluetoothSocket socket;
    private OutputStream salida;
    private Thread lector;
    private volatile int generacion = 0;

    public AcuarisBluetooth(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "AcuarisBluetooth";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> s = new HashSet<>();
        s.add(new SignalInfo("bt_datos", String.class));
        s.add(new SignalInfo("bt_estado", String.class, String.class));
        s.add(new SignalInfo("bt_permisos", Boolean.class));
        return s;
    }

    // ------------------------------------------------------------------ permisos
    @UsedByGodot
    public boolean tiene_permisos() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true;
        }
        Context c = getContext();
        return c != null && c.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
    }

    @UsedByGodot
    public void solicitar_permisos() {
        if (tiene_permisos()) {
            emitir("bt_permisos", Boolean.TRUE);
            return;
        }
        final Activity a = getActivity();
        if (a == null) {
            emitir("bt_permisos", Boolean.FALSE);
            return;
        }
        runOnHostThread(() -> a.requestPermissions(new String[] { Manifest.permission.BLUETOOTH_CONNECT }, PETICION_PERMISOS));
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PETICION_PERMISOS) {
            boolean ok = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
            emitir("bt_permisos", ok);
        }
    }

    // ------------------------------------------------------------------ adaptador
    private BluetoothAdapter adaptador() {
        Context c = getContext();
        if (c == null) {
            return null;
        }
        BluetoothManager m = (BluetoothManager) c.getSystemService(Context.BLUETOOTH_SERVICE);
        return m != null ? m.getAdapter() : null;
    }

    @UsedByGodot
    public boolean bluetooth_activo() {
        BluetoothAdapter a = adaptador();
        return a != null && a.isEnabled();
    }

    @UsedByGodot
    public String dispositivos_emparejados() {
        JSONArray lista = new JSONArray();
        BluetoothAdapter a = adaptador();
        if (a == null || !tiene_permisos()) {
            return lista.toString();
        }
        try {
            for (BluetoothDevice d : a.getBondedDevices()) {
                JSONObject o = new JSONObject();
                o.put("nombre", d.getName() != null ? d.getName() : "(sin nombre)");
                o.put("direccion", d.getAddress());
                lista.put(o);
            }
        } catch (SecurityException e) {
            Log.w(TAG, "Sin permiso para listar dispositivos", e);
        } catch (Exception e) {
            Log.w(TAG, "Error listando dispositivos", e);
        }
        return lista.toString();
    }

    // ------------------------------------------------------------------ conexión
    @UsedByGodot
    public void conectar(final String direccion) {
        final int mia;
        synchronized (cerrojo) {
            generacion++;
            mia = generacion;
        }
        cerrar();
        emitir("bt_estado", "conectando", direccion);
        Thread t = new Thread(() -> abrir(direccion, mia), "AcuarisBT-conexion");
        t.setDaemon(true);
        t.start();
    }

    private void abrir(String direccion, int mia) {
        BluetoothAdapter a = adaptador();
        if (a == null || !a.isEnabled()) {
            emitir("bt_estado", "error", "Bluetooth apagado o no disponible");
            return;
        }
        if (!tiene_permisos()) {
            emitir("bt_estado", "error", "Falta el permiso de Bluetooth");
            return;
        }
        BluetoothSocket s = null;
        String nombre = direccion;
        try {
            BluetoothDevice d = a.getRemoteDevice(direccion);
            if (d.getName() != null) {
                nombre = d.getName();
            }
            try {
                s = d.createRfcommSocketToServiceRecord(SPP);
                s.connect();
            } catch (IOException primero) {
                // Alternativa habitual para HC-05/HC-06: canal RFCOMM 1 directo.
                Log.w(TAG, "Conexión SPP estándar fallida, probando canal 1", primero);
                cerrarSilencioso(s);
                Method m = d.getClass().getMethod("createRfcommSocket", int.class);
                s = (BluetoothSocket) m.invoke(d, 1);
                s.connect();
            }
            synchronized (cerrojo) {
                if (mia != generacion) {
                    cerrarSilencioso(s);
                    return;
                }
                socket = s;
                salida = s.getOutputStream();
            }
            final InputStream entrada = s.getInputStream();
            lector = new Thread(() -> leer(entrada, mia), "AcuarisBT-lector");
            lector.setDaemon(true);
            lector.start();
            emitir("bt_estado", "conectado", nombre);
        } catch (SecurityException e) {
            cerrarSilencioso(s);
            emitir("bt_estado", "error", "Permiso de Bluetooth denegado");
        } catch (Exception e) {
            cerrarSilencioso(s);
            String msg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            emitir("bt_estado", "error", "No se pudo conectar con " + nombre + ": " + msg);
        }
    }

    private void leer(InputStream entrada, int mia) {
        byte[] buf = new byte[512];
        try {
            while (true) {
                int n = entrada.read(buf);
                if (n < 0) {
                    break;
                }
                if (n > 0) {
                    emitir("bt_datos", new String(buf, 0, n, StandardCharsets.ISO_8859_1));
                }
            }
        } catch (IOException e) {
            Log.i(TAG, "Lectura terminada: " + e.getMessage());
        }
        boolean actual;
        synchronized (cerrojo) {
            actual = mia == generacion;
        }
        if (actual) {
            cerrar();
            emitir("bt_estado", "desconectado", "Conexión perdida");
        }
    }

    @UsedByGodot
    public void enviar(final String texto) {
        escritor.execute(() -> {
            OutputStream o;
            synchronized (cerrojo) {
                o = salida;
            }
            if (o == null) {
                return;
            }
            try {
                o.write(texto.getBytes(StandardCharsets.ISO_8859_1));
                o.flush();
            } catch (IOException e) {
                cerrar();
                emitir("bt_estado", "desconectado", "Error al enviar: " + e.getMessage());
            }
        });
    }

    @UsedByGodot
    public void desconectar() {
        synchronized (cerrojo) {
            generacion++;
        }
        cerrar();
    }

    private void cerrar() {
        BluetoothSocket s;
        synchronized (cerrojo) {
            s = socket;
            socket = null;
            salida = null;
        }
        cerrarSilencioso(s);
    }

    private static void cerrarSilencioso(BluetoothSocket s) {
        if (s != null) {
            try {
                s.close();
            } catch (IOException ignored) {
            }
        }
    }

    @Override
    public void onMainDestroy() {
        desconectar();
        escritor.shutdownNow();
    }

    /** Las señales se entregan en el hilo de Godot. */
    private void emitir(final String senal, final Object... args) {
        runOnRenderThread(() -> emitSignal(senal, args));
    }
}
