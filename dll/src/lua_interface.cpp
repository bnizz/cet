// lua_interface.cpp - Consolidated Lua interface for CET
// Handles both DLL communication and translation functionality

#include <windows.h>
#include <string>
#include <sstream>
#include <vector>

#ifdef MINHOOK_AVAILABLE
#include "MinHook.h"
#endif

#include "../include/lua_interface.h"
#include "../include/translator_core.h"
#include "../include/logging.h"
#include "../include/utils.h"

using namespace std;

// Lua function pointer types (following UnitXP_SP3 exactly)
typedef void* (__fastcall* GETCONTEXT)(void);
typedef void (__fastcall* LUA_PUSHSTRING)(void* L, const char* s);
typedef void (__fastcall* LUA_PUSHBOOLEAN)(void* L, int boolean_value);
typedef void (__fastcall* LUA_PUSHNUMBER)(void* L, double n);
typedef void (__fastcall* LUA_PUSHNIL)(void* L);
typedef const char* (__fastcall* LUA_TOSTRING)(void* L, int index);
typedef double (__fastcall* LUA_TONUMBER)(void* L, int index);
typedef int (__fastcall* LUA_TOBOOLEAN)(void* L, int index);
typedef int (__fastcall* LUA_GETTOP)(void* L);
typedef int (__fastcall* LUA_ISNUMBER)(void* L, int index);
typedef int (__fastcall* LUA_ISSTRING)(void* L, int index);

// Memory addresses for Turtle WoW Lua functions (from working UnitXP_SP3)
static auto p_GetContext = reinterpret_cast<GETCONTEXT>(0x7040D0);
static auto p_lua_pushstring = reinterpret_cast<LUA_PUSHSTRING>(0x006F3890);
static auto p_lua_pushboolean = reinterpret_cast<LUA_PUSHBOOLEAN>(0x006F39F0);
static auto p_lua_pushnumber = reinterpret_cast<LUA_PUSHNUMBER>(0x006F3810);
static auto p_lua_pushnil = reinterpret_cast<LUA_PUSHNIL>(0x006F37F0);
static auto p_lua_tostring = reinterpret_cast<LUA_TOSTRING>(0x006F3690);
static auto p_lua_tonumber = reinterpret_cast<LUA_TONUMBER>(0x006F3620);
static auto p_lua_toboolean = reinterpret_cast<LUA_TOBOOLEAN>(0x6F3660);
static auto p_lua_gettop = reinterpret_cast<LUA_GETTOP>(0x006F3070);
static auto p_lua_isnumber = reinterpret_cast<LUA_ISNUMBER>(0x006F34D0);
static auto p_lua_isstring = reinterpret_cast<LUA_ISSTRING>(0x6F3510);

// Hook target - we hook the UnitXP function and replace it with CET
static auto p_UnitXP = reinterpret_cast<LUA_CFUNCTION>(0x517350);  // Same as UnitXP_SP3
static LUA_CFUNCTION p_original_UnitXP = nullptr;

// State tracking
static bool g_initialized = false;

// Helper functions
void* GetLuaContext() {
    void* result = p_GetContext();
    if (!result) {
        LOG_ERROR("Lua context is NULL");
    }
    return result;
}

void lua_pushstring(void* L, const string& str) {
    if (p_lua_pushstring && L) {
        p_lua_pushstring(L, str.c_str());
    }
}

void lua_pushboolean(void* L, bool value) {
    if (p_lua_pushboolean && L) {
        p_lua_pushboolean(L, value ? 1 : 0);
    }
}

void lua_pushnumber(void* L, double value) {
    if (p_lua_pushnumber && L) {
        p_lua_pushnumber(L, value);
    }
}

void lua_pushnil(void* L) {
    if (p_lua_pushnil && L) {
        p_lua_pushnil(L);
    }
}

string lua_tostring(void* L, int index) {
    if (!p_lua_tostring || !L) return "";
    const char* ptr = p_lua_tostring(L, index);
    return ptr ? string(ptr) : "";
}

double lua_tonumber(void* L, int index) {
    if (!p_lua_tonumber || !L) return 0.0;
    return p_lua_tonumber(L, index);
}

bool lua_toboolean(void* L, int index) {
    if (!p_lua_toboolean || !L) return false;
    return p_lua_toboolean(L, index) != 0;
}

int lua_gettop(void* L) {
    if (!p_lua_gettop || !L) return 0;
    return p_lua_gettop(L);
}

bool lua_isnumber(void* L, int index) {
    if (!p_lua_isnumber || !L) return false;
    return p_lua_isnumber(L, index) != 0;
}

bool lua_isstring(void* L, int index) {
    if (!p_lua_isstring || !L) return false;
    return p_lua_isstring(L, index) != 0;
}

// Main CET command handler - following exact UnitXP_SP3 pattern like working DLua
int __fastcall detoured_UnitXP(void* L) {
    try {
        if (lua_gettop(L) >= 1) {
            string cmd{ lua_tostring(L, 1) };
            
            // Check if this is a CET command - use "CET" as the first parameter
            if (cmd == "CET") {
                LOG_DEBUG("CET command intercepted");
                
                if (lua_gettop(L) >= 2) {
                    string subcmd{ lua_tostring(L, 2) };
                    
                    if (subcmd == "ping") {
                        lua_pushstring(L, "CET pong - DLL communication active");
                        LOG_DEBUG("CET Ping -> Pong");
                        return 1;
                    }
                    else if (subcmd == "version") {
                        lua_pushstring(L, "CET v1.0.0 - Chat Event Trigger with Translation");
                        return 1;
                    }
                    else if (subcmd == "status") {
                        string status = "CET Status: DLL Active, Translator ";
                        status += (g_translator && g_translator->IsInitialized()) ? "Ready" : "Not Ready";
                        lua_pushstring(L, status);
                        return 1;
                    }
                    else if (subcmd == "init_translator") {
                        if (lua_gettop(L) >= 3) {
                            string apiKey{ lua_tostring(L, 3) };
                            
                            if (g_translator && g_translator->Initialize(apiKey)) {
                                lua_pushstring(L, "CET translator initialized successfully");
                                LOG_INFO("Translator initialized with API key");
                            } else {
                                lua_pushstring(L, "CET init_translator error: initialization failed");
                                LOG_ERROR("Translator initialization failed");
                            }
                            return 1;
                        }
                        lua_pushstring(L, "CET init_translator error: API key required");
                        return 1;
                    }
                    else if (subcmd == "translate") {
                        if (lua_gettop(L) >= 5) {
                            string text{ lua_tostring(L, 3) };
                            string fromLang{ lua_tostring(L, 4) };
                            string toLang{ lua_tostring(L, 5) };
                            
                            if (!g_translator || !g_translator->IsInitialized()) {
                                lua_pushstring(L, "CET translate error: translator not initialized");
                                return 1;
                            }
                            
                            if (text.empty()) {
                                lua_pushstring(L, "CET translate error: empty text provided");
                                return 1;
                            }
                            
                            string result;
                            TranslationResult translateResult = g_translator->TranslateText(text, fromLang, toLang, result);
                            
                            if (translateResult == TranslationResult::SUCCESS) {
                                lua_pushstring(L, result);
                                LOG_DEBUG("Translation successful: " + text + " -> " + result);
                            } else {
                                string error = "CET translate error: ";
                                switch (translateResult) {
                                    case TranslationResult::NETWORK_ERROR: error += "network error"; break;
                                    case TranslationResult::API_ERROR: error += "API error"; break;
                                    case TranslationResult::ENCODING_ERROR: error += "encoding error"; break;
                                    case TranslationResult::TIMEOUT_ERROR: error += "timeout"; break;
                                    case TranslationResult::INVALID_PARAMS: error += "invalid parameters"; break;
                                    default: error += "unknown error"; break;
                                }
                                lua_pushstring(L, error);
                                LOG_ERROR("Translation failed: " + error);
                            }
                            return 1;
                        }
                        lua_pushstring(L, "CET translate error: insufficient arguments (text, fromLang, toLang required)");
                        return 1;
                    }
                    else {
                        string error = "CET: Unknown command '" + subcmd + "'";
                        lua_pushstring(L, error);
                        return 1;
                    }
                } else {
                    lua_pushstring(L, "CET: No subcommand specified");
                    return 1;
                }
            }
        }
        
        // Not our command - call original UnitXP if available
        if (p_original_UnitXP) {
            return p_original_UnitXP(L);
        }
        
        // Fallback - return 0 if no original function
        return 0;
        
    } catch (const exception& e) {
        string error = "CET Exception: " + string(e.what());
        LOG_ERROR(error);
        lua_pushstring(L, error);
        return 1;
    } catch (...) {
        string error = "CET Unknown Exception";
        LOG_ERROR(error);
        lua_pushstring(L, error);
        return 1;
    }
}

// Initialize the Lua interface by hooking UnitXP
bool InitializeLuaInterface() {
    if (g_initialized) {
        LOG_WARNING("Lua interface already initialized");
        return true;
    }

    LOG_INFO("Initializing CET Lua interface...");

#ifdef MINHOOK_AVAILABLE
    // Initialize MinHook
    if (MH_Initialize() != MH_OK) {
        LOG_ERROR("Failed to initialize MinHook");
        return false;
    }

    // Hook the UnitXP function with our CET handler
    if (MH_CreateHook(reinterpret_cast<LPVOID>(p_UnitXP), 
                      reinterpret_cast<LPVOID>(detoured_UnitXP), 
                      reinterpret_cast<LPVOID*>(&p_original_UnitXP)) != MH_OK) {
        LOG_ERROR("Failed to create hook for UnitXP function");
        return false;
    }

    if (MH_EnableHook(reinterpret_cast<LPVOID>(p_UnitXP)) != MH_OK) {
        LOG_ERROR("Failed to enable hook for UnitXP function");
        return false;
    }

    LOG_INFO("Successfully hooked UnitXP function with CET handler");
#else
    LOG_WARNING("MinHook not available - direct memory patching not supported");
    LOG_INFO("CET will be available but requires manual function replacement");
#endif

    g_initialized = true;
    LOG_INFO("CET Lua interface initialization complete");
    return true;
}

// Cleanup the Lua interface
void CleanupLuaInterface() {
    if (!g_initialized) {
        return;
    }

    LOG_INFO("Cleaning up CET Lua interface...");

#ifdef MINHOOK_AVAILABLE
    // Disable and remove hook
    MH_DisableHook(reinterpret_cast<LPVOID>(p_UnitXP));
    MH_RemoveHook(reinterpret_cast<LPVOID>(p_UnitXP));
    MH_Uninitialize();
#endif

    g_initialized = false;
    LOG_INFO("CET Lua interface cleanup complete");
}
