# Chinese English Translator OR Chat Event Trigger (CET)

A unified World of Warcraft 1.12.1 addon that provides real-time translation of chat messages using Google Translate API with bidirectional DLL communication.

## Overview

This upload was limited to what was needed to make the thing run and I also provided the source for DLL compilation.
Besides adding the addon files to CET directory in your addons folder, and the CET.dll to your root WoW folder, you probably also need to update your dlls.txt file adding CET.dll, and you might also need to tag the dll in launcher if using standard launcher.
You also need to create a Google Translate API key in order to make translations work.

I hope to improve this as I test it, but I usually don't have a lot of free time. Feel free to fork it and make it better or provide me feedback on your experience with it.
I added some additional sections in the readme which aim to help with deploying the addon and also setting up the translate API key.
These 2 sections (Google Cloud Translation API Setup & Deployment Guide) should be all you need to actually use the solution.

CET combines three key components into a single, production-ready solution:
- **Chat Event Monitoring**: Configurable tracking of WoW chat channels
- **Real-time Translation**: Google Translate API integration via DLL
- **Bidirectional Communication**: Secure addon ↔ DLL communication using UnitXP interface

## 🌐 Google Cloud Translation API Setup

### 💰 Pricing & Quotas Information

Before setting up the Google Cloud Translation API, please review the pricing and quota information to understand potential costs:

- **📋 Pricing Details**: [Google Cloud Translation Basic Pricing](https://cloud.google.com/translate/pricing#basic-pricing)
- **📊 Usage Quotas**: [Google Cloud Translation Quotas](https://cloud.google.com/translate/quotas)

> ⚠️ **Important**: You may be prompted to setup payment information during this process. If you're concerned about being billed beyond the free tier, implementing usage quotas is strongly advised.

### 🚀 Setup Instructions

#### Step 1: Create or Select a Project

1. Visit the [Google Cloud Console Project Selector](https://console.cloud.google.com/projectselector2)
2. Choose one of the following options:
   - **Create a new project**: Click **"Create Project"**
   - **Use existing project**: Select an existing project if that makes more sense for your use case

#### Step 2: Turn on Cloud Translation API

   1. visit https://console.cloud.google.com/
   2. Open left side menu
   3. Click apis & services
   4. Click + enable apis and services
   5. Search for translate
   6. Click on cloud translation api -> turn it on

#### Step 3: Generate API Credentials

1. **Navigate to APIs & Services**:
   - Click the navigation menu (hamburger icon) in the top left corner
   - Select **"APIs & Services"**
   - Click on **"Credentials"** at the top of the page

2. **Create API Key**:
   - Click the **"Create Credentials"** dropdown
   - Select **"API Key"**

### 🔒 Security Best Practices

> 🛡️ **Critical Security Note**: Keep your API key safe and secure! Anyone with access to this key would be able to use your Google Cloud account and potentially incur charges.

#### Recommended Security Measures:
- Store your API key in environment variables
- Never commit API keys to version control
- Restrict API key usage to specific APIs and services
- Regularly rotate your API keys
- Monitor your usage in the Google Cloud Console

### 📈 Monitoring Usage

To avoid unexpected charges:
- Set up billing alerts in your Google Cloud Console
- Implement usage quotas for the Translation API
- Regularly monitor your API usage and costs
- Consider implementing rate limiting in your application

---

*Need help? Check the [Google Cloud Translation API documentation](https://cloud.google.com/translate/docs) for additional guidance.*

## 🐢 Deployment Guide

### Prerequisites
- Turtle WoW client installed and working
- Administrative access to modify game files

### 📥 Deployment Steps

#### 1. Download the Release
- Navigate to the [releases page](https://github.com/bnizz/cet/releases/tag/alpha)
- Download the latest ZIP file from the releases section

#### 2. Extract Files
- Unzip the downloaded file to a temporary location
- You should see a `CET` folder and `CET.dll` file

#### 3. Install Addon
```
📁 gamedir/
├── 📁 Interface/
│   └── 📁 AddOns/
│       └── 📁 CET/          ← Copy this folder here
└── CET.dll                  ← Copy this file here
```

**Steps:**
- Copy the `CET` folder into your `gamedir/Interface/AddOns/` directory
- Copy the `CET.dll` file into your main `gamedir/` directory

#### 4. Configure DLL Loading
- Open `dlls.txt` file in your game directory
- Add the following line: `CET.dll`
- Save the file

#### 5. Enable in Launcher (Optional)
Some users may need to:
- Open the launcher
- Navigate to the **MODS** tab
- Enable the CET DLL
- Click **Apply**

### ✅ Verification

After installation, launch WoW and verify that:
- The game starts without errors
- CET functionality is available in-game
- No DLL loading errors appear

### 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Game won't start | Check that `CET.dll` is in the correct directory and listed in `dlls.txt` |
| Addon not loading | Verify the `CET` folder is in `Interface/AddOns/` |
| DLL errors | Try enabling the DLL in the launcher's MODS tab |

### 📂 File Structure
After successful installation, your directory should look like:
```
Game Folder/
├── CET.dll
├── dlls.txt (containing "CET.dll")
└── Interface/
    └── AddOns/
        └── CET/
            └── [addon files]
```

---

> ⚠️ **Important**: Always backup your game files before installing any modifications.

## WoW V1.12.1 Chinese & Russian Font Guide
Info primarily sourced from https://forum.turtle-wow.org/viewtopic.php?t=8326
Content there also has some screenshots

### Overview
A guide for viewing, copying, and pasting Chinese and Russian characters in Turtle WoW.

### Font Installation

#### Download Required Font
- Download the font pack from [here](https://raw.githubusercontent.com/bnizz/cet/main/ARIALN.ttf)
- Extract fonts to `..\\Game Folder\\Fonts` (create new Fonts folder if needed)

#### pfUI Users Additional Steps
- Copy font to `..\\Game Folder\\Interface\\AddOns\\pfUI\\fonts`
- Update pfUI font settings in the addon configuration

- To update pfUI, open config and enable the ARIALN font for UI elements which are showing blank characters
- Settings -> General -> Standard Text Font is the main setting I think

### Locale Emulator Setup
This section is only if you wish to copy / paste Chinese characters yourself

#### Installation
- Download Locale Emulator from GitHub (v2.5.0.1)
- Run `LEInstaller.exe` to install
- Launch `LEGUI.exe`

#### Chinese Profile Configuration
- Create a new Chinese profile with these settings:
  - Location: China (People's Republic of)
  - Language: Chinese (Simplified)
  - Code Page: 936 (ANSI/OEM Simplified Chinese GBK)

#### Running WoW with Chinese Support
- Right-click on `WoW.exe` or `WoWFoV.exe`
- Select: Locale Emulator → Chinese

### Optional Tools

#### Shortcut Creation
- Use [LEShortcutCreator](https://github.com/Svintooo/LEShortcutCreator) to create desktop shortcuts
- Eliminates need to right-click every time

#### Text Copying Addons
- **ShaguCopy**: Dedicated text copying addon
- **pfUI**: Built-in text copying functionality

### Troubleshooting

#### LEGUI Profile Issues
If LEGUI only shows Japanese options:
1. Manually edit `LEConfig.xml` file
2. Copy existing profile section and modify for Chinese
3. Generate new GUID using PowerShell: `[Guid]::NewGuid()`

## Architecture

### Project Structure
```
cet/
├── addon/                 # WoW Addon Files
│   ├── CET.toc           # Addon metadata
│   ├── CETDefaults.lua   # Default configurations
│   ├── CETVars.lua       # Variable management
│   ├── CET.lua           # Main addon logic
│   ├── CETUI.lua         # User interface logic
│   └── CETUI.xml         # User interface layout
├── dll/                  # Consolidated DLL
│   ├── src/              # Source code
│   ├── include/          # Header files
│   ├── third_party/      # MinHook library
│   └── CMakeLists.txt    # Build configuration
└── scripts/              # Build and deployment scripts
```

### Communication Flow
```
WoW Chat Event → Addon Logic → UnitXP Interface → CET.dll → Google Translate API
                     ↓                                           ↓
            Display Translation ← Lua Interface ← DLL Response ← Translation Result
```

### Key Components

1. **CET.lua**: Main event handling, chat processing, and command interface
2. **CETVars.lua**: Configuration management with persistent storage
3. **CETUI.lua**: Graphical user interface for easy configuration
4. **translator_core.cpp**: Google Translate API client with caching
5. **lua_interface.cpp**: Secure bidirectional addon-DLL communication

## Performance

### Optimizations
- **Translation Caching**: 1-hour cache prevents repeated API calls
- **Efficient Memory Management**: Smart pointers and RAII patterns
- **Minimal Hook Footprint**: Uses existing UnitXP interface
- **Background Processing**: Non-blocking translation requests

### Resource Usage
- **Memory**: ~2-5MB runtime footprint
- **Network**: Only for new translations (cached results = no network)
- **CPU**: Minimal impact on game performance

## Error Handling

### Common Issues

1. **"UnitXP not available"**
   - Solution: Install UnitXP or compatible addon framework
   
2. **"Translator not initialized"**
   - Solution: Set valid Google Translate API key with `/cet apikey`
   
3. **"DLL not connected"**
   - Solution: Ensure CET.dll is in WoW directory and loaded
   
4. **Translation failures**
   - Check API key validity
   - Verify internet connection
   - Check language codes are valid

### Debug Mode

Enable debug mode for detailed logging:
```
/cet debug
```

Check the log file: `CET.log` in your WoW directory.

## Development

### Building from Source

Requirements:
- Visual Studio 2019+ or compatible C++ compiler
- CMake 3.20+
- Windows SDK

Build steps:
```powershell
cd cet/dll
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

### Adding Language Support

To add new language codes, edit `utils.cpp` and `CETDefaults.lua`:

1. Add language code to `IsValidLanguageCode()` function
2. Add to `CETDefaults.isValidLanguageCode()` array
3. Test with `/cet direction <new_code> en`

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or feature requests:
1. Check the troubleshooting section above
2. Enable debug mode and check the log file
3. Create an issue with detailed information

## Acknowledgments

- UnitXP_SP3 for the communication pattern
- Google Translate API for translation services
- MinHook library for safe function hooking
- WoW modding community for documentation and support













