#pragma once

#include <windows.h>
#include <winhttp.h>
#include <string>
#include <unordered_map>
#include <memory>

// Translation result codes
enum class TranslationResult {
    SUCCESS = 0,
    NETWORK_ERROR = 1,
    API_ERROR = 2,
    ENCODING_ERROR = 3,
    TIMEOUT_ERROR = 4,
    INVALID_PARAMS = 5
};

// Cache entry structure
struct CacheEntry {
    std::string translation;
    DWORD timestamp;
    
    CacheEntry() : translation(""), timestamp(0) {}
    CacheEntry(const std::string& trans) 
        : translation(trans), timestamp(GetTickCount()) {}
};

// Translation client class
class TranslationClient {
private:
    HINTERNET hSession;
    HINTERNET hConnect;
    std::string apiKey;
    std::unordered_map<std::string, CacheEntry> cache;
    bool initialized;
    
    static const DWORD CACHE_EXPIRY_MS = 3600000; // 1 hour
    static const size_t MAX_CACHE_SIZE = 1000;
    
    // Helper methods
    std::string UrlEncode(const std::string& text);
    std::string HttpsRequest(const std::string& host, const std::string& path, const std::string& postData);
    std::string ParseTranslationResponse(const std::string& jsonResponse);
    std::string UTF8ToWide(const std::string& utf8);
    std::string WideToUTF8(const std::wstring& wide);
    std::string GenerateCacheKey(const std::string& text, const std::string& fromLang, const std::string& toLang);
    void CleanExpiredCache();
    
public:
    TranslationClient();
    ~TranslationClient();
    
    bool Initialize(const std::string& key);
    void Cleanup();
    TranslationResult TranslateText(const std::string& text, const std::string& fromLang, 
                                   const std::string& toLang, std::string& result);
    bool IsInitialized() const { return initialized; }
};

// Global translation instance
extern std::unique_ptr<TranslationClient> g_translator;

// Static buffers for Lua interface
extern char g_translation_buffer[4096];
extern char g_error_buffer[256];
