// utils.cpp - Utility functions for CET

#include <windows.h>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>
#include <iomanip>
#include <ctime>
#include <unordered_set>

#include "../include/utils.h"

using namespace std;

string GetCurrentTimestamp() {
    time_t now = time(0);
    tm timeinfo;
    localtime_s(&timeinfo, &now);
    
    ostringstream oss;
    oss << put_time(&timeinfo, "%Y-%m-%d %H:%M:%S");
    return oss.str();
}

string GetDllPath() {
    char path[MAX_PATH];
    HMODULE hModule = nullptr;
    
    // Get handle to this DLL
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                          GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                          (LPCSTR)&GetDllPath, &hModule) == 0) {
        return "";
    }
    
    // Get the full path
    if (GetModuleFileNameA(hModule, path, MAX_PATH) == 0) {
        return "";
    }
    
    return string(path);
}

vector<string> SplitString(const string& str, char delimiter) {
    vector<string> tokens;
    stringstream ss(str);
    string token;
    
    while (getline(ss, token, delimiter)) {
        tokens.push_back(token);
    }
    
    return tokens;
}

string TrimString(const string& str) {
    size_t start = str.find_first_not_of(" \t\n\r\f\v");
    if (start == string::npos) {
        return "";
    }
    
    size_t end = str.find_last_not_of(" \t\n\r\f\v");
    return str.substr(start, end - start + 1);
}

bool IsValidLanguageCode(const string& lang) {
    // Common language codes supported by Google Translate
    static const unordered_set<string> validCodes = {
        "af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca", "ceb", "ny",
        "zh", "zh-cn", "zh-tw", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "tl", "fi",
        "fr", "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "iw", "he", "hi", "hmn",
        "hu", "is", "ig", "id", "ga", "it", "ja", "jw", "kn", "kk", "km", "ko", "ku", "ky",
        "lo", "la", "lv", "lt", "lb", "mk", "mg", "ms", "ml", "mt", "mi", "mr", "mn", "my",
        "ne", "no", "or", "ps", "fa", "pl", "pt", "pa", "ro", "ru", "sm", "gd", "sr", "st",
        "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tg", "ta", "te", "th",
        "tr", "uk", "ur", "ug", "uz", "vi", "cy", "xh", "yi", "yo", "zu"
    };
    
    string lowerLang = lang;
    transform(lowerLang.begin(), lowerLang.end(), lowerLang.begin(), ::tolower);
    
    return validCodes.find(lowerLang) != validCodes.end();
}

bool IsValidMemoryAddress(void* addr) {
    if (addr == nullptr) {
        return false;
    }
    
    MEMORY_BASIC_INFORMATION mbi;
    if (VirtualQuery(addr, &mbi, sizeof(mbi)) == 0) {
        return false;
    }
    
    return (mbi.State == MEM_COMMIT) && 
           (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | 
                          PAGE_READONLY | PAGE_READWRITE));
}

void* SafeGetProcAddress(HMODULE hModule, const char* procName) {
    if (!hModule || !procName) {
        return nullptr;
    }
    
    __try {
        return GetProcAddress(hModule, procName);
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        return nullptr;
    }
}
