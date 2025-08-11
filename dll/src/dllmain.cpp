// dllmain.cpp - Main DLL entry point for Chat Event Trigger (CET)
// Combines translation functionality with Lua communication

#include <windows.h>
#include <string>

#include "../include/lua_interface.h"
#include "../include/translator_core.h"
#include "../include/logging.h"
#include "../include/utils.h"

using namespace std;

// Global module handle
HMODULE g_hModule = nullptr;

// DLL entry point
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    {
        // Store module handle
        g_hModule = hModule;

        // Initialize logging first
        if (!InitializeLogging()) {
            MessageBoxW(NULL, L"Failed to initialize logging system.", L"CET Library", MB_OK | MB_ICONERROR);
            return FALSE;
        }

        LOG_INFO("CET Library: DLL_PROCESS_ATTACH");
        LOG_INFO("Initializing Chat Event Trigger library...");

        // Initialize translation client
        g_translator = std::make_unique<TranslationClient>();
        if (!g_translator) {
            LOG_ERROR("Failed to create translation client");
            MessageBoxW(NULL, L"Failed to initialize translation system.", L"CET Library", MB_OK | MB_ICONERROR);
            return FALSE;
        }

        // Initialize Lua interface
        if (!InitializeLuaInterface()) {
            LOG_ERROR("Failed to initialize Lua interface");
            MessageBoxW(NULL, L"Failed to initialize Lua interface.", L"CET Library", MB_OK | MB_ICONERROR);
            return FALSE;
        }

        LOG_INFO("CET Library initialization complete");
        break;
    }
    case DLL_PROCESS_DETACH:
    {
        LOG_INFO("CET Library: DLL_PROCESS_DETACH");
        
        // Cleanup in reverse order
        CleanupLuaInterface();
        
        if (g_translator) {
            g_translator->Cleanup();
            g_translator.reset();
        }
        
        CleanupLogging();
        break;
    }
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
        break;
    }
    return TRUE;
}
