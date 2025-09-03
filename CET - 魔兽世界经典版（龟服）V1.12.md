# CET - 魔兽世界经典版（龟服）V1.12.1客户端中英文翻译器

一个统一的魔兽世界1.12.1插件，使用Google翻译API通过双向DLL通信提供聊天消息的实时翻译。

本次上传仅限于运行所需的文件，同时我也提供了DLL编译的源代码。除了将插件文件添加到你的插件文件夹中的CET目录，以及将CET.dll放入WoW根目录外，你可能还需要更新dlls.txt文件添加CET.dll，如果使用标准启动器，你可能还需要在龟服启动器中标记该dll。你还需要创建一个Google翻译API密钥才能使翻译功能正常工作。

我希望在测试过程中改进它，但通常没有太多空闲时间。欢迎fork并改进它，或者提供使用体验的反馈。我在readme中添加了一些额外的部分，旨在帮助部署插件和设置翻译API密钥。这两个部分（Google Cloud翻译API设置和部署指南）应该是实际使用该解决方案所需的全部内容。

## 核心功能

CET将三个关键组件合并为一个生产就绪的解决方案：

- **聊天事件监控**：可配置的WoW聊天频道跟踪
- **实时翻译**：通过DLL集成Google翻译API
- **双向通信**：使用UnitXP接口的安全插件↔DLL通信

## Google Cloud翻译API设置

在设置Google Cloud翻译API之前，请查看定价和配额信息以了解潜在成本：

- 📋 **定价详情**：[Google Cloud翻译基础定价](https://cloud.google.com/translate/pricing#basic-pricing)
- 📊 **使用配额**：[Google Cloud翻译配额](https://cloud.google.com/translate/quotas)

⚠️ **重要提示**：在此过程中可能会提示您设置付款信息。如果您担心被收费超出免费层级，强烈建议实施使用配额。

### 步骤1：创建Google Cloud项目

- 访问[Google Cloud控制台项目选择器](https://console.cloud.google.com/projectselector2)
- 选择以下选项之一：
  - **创建新项目**：点击"创建项目"
  - **使用现有项目**：如果对您的用例更合适，选择现有项目

### 步骤2：启用翻译API

- 访问[https://console.cloud.google.com/](https://console.cloud.google.com/)
- 打开左侧菜单
- 点击"API和服务"
- 点击"+ 启用API和服务"
- 搜索"translate"
- 点击"Cloud Translation API" -> 启用

### 步骤3：创建API密钥

**导航到API和服务**：
- 点击左上角的导航菜单（汉堡包图标）
- 选择"API和服务"
- 点击页面顶部的"凭据"

**创建API密钥**：
- 点击"创建凭据"下拉菜单
- 选择"API密钥"

### 🛡️ 重要安全提示

**保护您的API密钥安全！**拥有此密钥访问权限的任何人都能够使用您的Google Cloud账户并可能产生费用。

- 将API密钥存储在环境变量中
- 永远不要将API密钥提交到版本控制
- 限制API密钥使用于特定的API和服务
- 定期轮换您的API密钥
- 在Google Cloud控制台中监控您的使用情况

**避免意外费用**：
- 在Google Cloud控制台中设置计费提醒
- 为翻译API实施使用配额
- 定期监控您的API使用和成本
- 考虑在应用程序中实施速率限制

需要帮助？查看[Google Cloud翻译API文档](https://cloud.google.com/translate/docs)获取更多指导。

## 部署指南

### 先决条件

- 龟服客户端已安装并正常工作
- 修改游戏文件的管理员权限

### 安装步骤

1. **下载文件**：
   - 导航到[发布页面](https://github.com/bnizz/cet/releases/tag/alpha)
   - 从发布部分下载最新的ZIP文件
   - 将下载的文件解压到临时位置
   - 您应该看到一个`CET`文件夹和`CET.dll`文件

2. **文件结构**：
```
📁 GameDirectory/
├── 📁 Interface/
│   └── 📁 AddOns/
│       └── 📁 CET/ ← 将此文件夹复制到这里
└── CET.dll ← 将此文件复制到这里
```

3. **复制文件**：
   - 将`CET`文件夹复制到您的`GameDirectory/Interface/AddOns/`目录
   - 将`CET.dll`文件复制到您的主`GameDirectory/`目录

4. **更新dlls.txt**：
   - 在GameDirectory目录中打开`dlls.txt`文件
   - 添加以下行：`CET.dll`
   - 保存文件

5. **启动器配置（如需要）**：
   一些用户可能需要：
   - 打开龟服启动器
   - 导航到MODS选项卡
   - 启用CET DLL
   - 点击应用

### 验证安装

安装后，启动龟服并验证：
- 游戏正常启动无错误
- CET功能在游戏中可用
- 没有出现DLL加载错误

### 故障排除

| 问题 | 解决方案 |
|---|---|
| 游戏无法启动 | 检查CET.dll是否在正确目录且在dlls.txt中列出 |
| 插件未加载 | 验证CET文件夹是否在Interface/AddOns/中 |
| DLL错误 | 尝试在启动器的MODS选项卡中启用DLL |

安装成功后，您的目录结构应该如下所示：
```
GameDirectory/
├── CET.dll
├── dlls.txt (包含"CET.dll")
└── Interface/
    └── AddOns/
        └── CET/
            └── [插件文件]
```

⚠️ **重要提示**：安装任何修改前始终备份您的游戏文件。

## 字体安装

信息主要来源：[https://forum.turtle-wow.org/viewtopic.php?t=8326](https://forum.turtle-wow.org/viewtopic.php?t=8326)
该内容还包含一些截图

在龟服中查看、复制和粘贴中文和俄文字符的指南。

### 字体安装步骤

- 从[这里](https://raw.githubusercontent.com/bnizz/cet/main/ARIALN.ttf)下载字体包
- 将字体解压到`..\\GameDirectory\\Fonts`（如需要请创建新的Fonts文件夹）
- 将字体复制到`..\\GameDirectory\\Interface\\AddOns\\pfUI\\fonts`
- 在插件配置中更新pfUI字体设置
- 要更新pfUI，打开配置并为显示空白字符的UI元素启用ARIALN字体
- 设置 -> 通用 -> 标准文本字体是我认为的主要设置

## 字符复制/粘贴设置

此部分仅适用于您希望自己复制/粘贴中文字符的情况

### Locale Emulator设置

- 从GitHub下载Locale Emulator（v2.5.0.1）
- 运行`LEInstaller.exe`进行安装
- 启动`LEGUI.exe`
- 使用以下设置创建新的中文配置文件：
  - 位置：中国（人民共和国）
  - 语言：中文（简体）
  - 代码页：936（ANSI/OEM简体中文GBK）

### 启动游戏

- 右键点击`WoW.exe`或`WoWFoV.exe`
- 选择：Locale Emulator → Chinese

### 可选改进

- 使用[LEShortcutCreator](https://github.com/Svintooo/LEShortcutCreator)创建桌面快捷方式
- 无需每次都右键点击

### 文本复制解决方案

- **ShaguCopy**：专用的文本复制插件
- **pfUI**：内置文本复制功能

### 故障排除

如果LEGUI只显示日文选项：
- 手动编辑`LEConfig.xml`文件
- 复制现有配置文件部分并为中文修改
- 使用PowerShell生成新GUID：`[Guid]::NewGuid()`

## 项目结构

```
cet/
├── addon/                 # WoW插件文件
│   ├── CET.toc            # 插件元数据
│   ├── CETDefaults.lua    # 默认配置
│   ├── CETVars.lua        # 变量管理
│   ├── CET.lua            # 主插件逻辑
│   ├── CETUI.lua          # 用户界面逻辑
│   └── CETUI.xml          # 用户界面布局
├── dll/                   # 整合DLL
│   ├── src/               # 源代码
│   ├── include/           # 头文件
│   ├── third_party/       # MinHook库
│   └── CMakeLists.txt     # 构建配置
└── scripts/               # 构建和部署脚本
```

## 架构概览

```
WoW聊天事件 → 插件逻辑 → UnitXP接口 → CET.dll → Google翻译API
    ↓                                                      ↓
显示翻译 ← Lua接口 ← DLL响应 ← 翻译结果
```

### 关键组件

- **CET.lua**：主事件处理、聊天处理和命令接口
- **CETVars.lua**：带持久存储的配置管理
- **CETUI.lua**：便于配置的图形用户界面
- **translator_core.cpp**：带缓存的Google翻译API客户端
- **lua_interface.cpp**：安全的双向插件-DLL通信

## 性能特性

- **翻译缓存**：1小时缓存防止重复API调用
- **高效内存管理**：智能指针和RAII模式
- **最小Hook占用**：使用现有UnitXP接口
- **后台处理**：非阻塞翻译请求

### 资源使用

- **内存**：~2-5MB运行时占用
- **网络**：仅用于新翻译（缓存结果 = 无网络）
- **CPU**：对游戏性能影响最小

## 故障排除

### 常见问题

- **"UnitXP不可用"**
  - 解决方案：安装UnitXP或兼容的插件框架

- **"翻译器未初始化"**
  - 解决方案：使用`/cet apikey`设置有效的Google翻译API密钥

- **"DLL未连接"**
  - 解决方案：确保CET.dll在WoW目录中并已加载

- **翻译失败**
  - 检查API密钥有效性
  - 验证网络连接
  - 检查语言代码是否有效

### 调试

启用详细日志的调试模式：
```
/cet debug
```

检查WoW目录中的日志文件：`CET.log`

## 开发

### 构建要求

- Visual Studio 2019+或兼容的C++编译器
- CMake 3.20+
- Windows SDK

### 构建步骤

```bash
cd cet/dll
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

### 添加新语言

要添加新语言代码，编辑`utils.cpp`和`CETDefaults.lua`：

- 将语言代码添加到`IsValidLanguageCode()`函数
- 添加到`CETDefaults.isValidLanguageCode()`数组
- 使用`/cet direction <new_code> en`进行测试

## 贡献

- Fork仓库
- 创建功能分支（`git checkout -b feature/amazing-feature`）
- 提交更改（`git commit -m 'Add amazing feature'`）
- 推送到分支（`git push origin feature/amazing-feature`）
- 打开Pull Request

## 许可证

本项目采用MIT许可证 - 详情请参阅LICENSE文件。

## 支持

如有问题、疑问或功能请求：

- 查看上面的故障排除部分
- 启用调试模式并检查日志文件
- 创建包含详细信息的issue

## 致谢

- UnitXP_SP3提供通信模式
- Google翻译API提供翻译服务
- MinHook库提供安全函数挂钩

- WoW模组社区提供文档和支持
