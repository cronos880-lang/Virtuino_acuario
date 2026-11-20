#pragma once
#define WDTO_8S 9
extern int g_wdt_activo;
inline void wdt_enable(int) { g_wdt_activo = 1; }
inline void wdt_disable() { g_wdt_activo = 0; }
inline void wdt_reset() {}
