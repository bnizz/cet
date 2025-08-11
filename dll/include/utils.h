#pragma once

#include <string>
#include <vector>

// Utility functions
std::string GetCurrentTimestamp();
std::string GetDllPath();
std::vector<std::string> SplitString(const std::string& str, char delimiter);
std::string TrimString(const std::string& str);
bool IsValidLanguageCode(const std::string& lang);

// Memory utility functions
bool IsValidMemoryAddress(void* addr);
void* SafeGetProcAddress(HMODULE hModule, const char* procName);
