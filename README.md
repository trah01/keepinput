# KeepInput

默认语言：简体中文

其他语言： [English](README.en.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [日本語](README.ja.md)

KeepInput 是一个轻量级 macOS 菜单栏应用，用于锁定当前输入法，减少在写作、编程或跨应用切换时误触切换输入法的问题。

本仓库基于 [bigccc/inputlock](https://github.com/bigccc/inputlock) 进行扩展

## 现有功能

| 功能 | 说明 |
| --- | --- |
| 输入法锁定 | 锁定当前输入法，被切换后自动恢复；面板显示当前输入法和锁定目标 |
| 临时切换 | 快捷键或列表切换到其他已启用输入法，再按快捷键立即恢复锁定 |
| 空闲恢复 | 停止输入后自动恢复，等待时间为 1–60 秒，默认 5 秒；持续输入时延后恢复 |
| 自定义快捷键 | 支持普通单键、功能键、Globe、Caps Lock、Shift、Option、Control、Command，以及修饰键组合和常规组合键 |
| 安全输入 | macOS 启用密码安全输入时暂停强制切换，结束后恢复锁定 |
| 菜单栏控制 | 左键打开面板，右键打开快速菜单；可隐藏图标，重新运行应用打开设置 |
| 开机启动 | 与系统登录项实际状态同步，需要批准时提供系统设置入口；支持另行开启恢复上次锁定 |
| 应用内更新 | 手动检查 GitHub Releases 正式版，下载 DMG 后重启安装 |
| 多语言 | 跟随系统，或选择简体中文、English、Français、Deutsch、日本語 |

## 系统要求

- macOS 12.0 Monterey 或更高版本
- 开机启动功能需要 macOS 13.0 或更高版本

## 安装

推荐从 GitHub Release 安装：

1. 打开 [Releases](https://github.com/trah01/keepinput/releases) 页面。
2. 下载最新的 `InputLock-1.3.dmg`。
3. 打开 DMG，把 `lockinput.app` 拖到 `Applications` 文件夹。
4. 从 `Applications` 启动 InputLock。

安装包使用本地 ad-hoc 签名，未经过 Apple 公证。如果首次启动被 macOS 拦截，可在“系统设置 > 隐私与安全性”中允许打开。确认安装包来自本项目 Releases，并已拖入“应用程序”后，也可在终端执行：

```bash
xattr -dr com.apple.quarantine /Applications/lockinput.app
```

然后重新打开应用。如果安装在其他位置，请替换命令中的路径；提示权限不足时再在命令前加 `sudo`。

## 使用

### 锁定与临时切换

1. 点击顶部菜单栏锁图标，选择要使用的输入法，再点击锁定按钮。
2. 已锁定时，点击列表中的其他输入法会临时切换；未锁定时直接切换。
3. 在设置中选择临时切换的目标输入法。未指定时自动选择 ABC/US 等英文键盘布局。
4. 按临时切换快捷键切换，再按一次立即恢复锁定；停止输入后也会按设置的等待时间自动恢复。

临时切换快捷键在锁定状态下生效。临时切换后，锁定目标保持原来的输入法；需要更换锁定目标时，使用面板的锁定按钮。

### 录制快捷键

1. 打开设置，点击“临时切换快捷键”右侧的录制按钮。
2. 普通按键或带修饰键的组合在按下普通按键时保存；仅由修饰键组成的组合，按完整个组合并松开后保存。Caps Lock 在切换时保存。
3. 再次点击录制按钮可取消，点击右侧 × 清除。Escape、Delete 也可以作为快捷键。

例如可以设置单独 `Option`、单独 `Control`、`Control + Option`、`Command + Shift + Space` 或 `F6`。纯修饰键组合在松开后触发，用它配合其他按键输入时不会触发临时切换。需要辅助功能权限时，设置页会显示授权入口；macOS 保留的组合可能同时触发系统操作。

### 设置与菜单栏图标

- 从主面板底部或菜单栏右键菜单打开设置；应用处于活动状态时也可按 `Command + ,`。
- 开启“隐藏菜单栏图标”后，顶部图标隐藏。再次运行应用会打开设置，关闭该开关即可恢复图标。
- “开机启动”开关显示系统的实际状态；需要批准时，点击“打开登录项设置”完成授权。
- 开启“重启后恢复上次锁定”后，下次启动恢复锁定目标。
- 界面语言可以跟随系统，也可以在设置中手动选择。

### 检查更新

在设置的“关于”区域点击“检查更新”，发现新版后选择“下载并重启”。请先将应用移出 DMG，放入有写入权限的应用程序文件夹。没有安装包或网络请求失败时，设置页会显示对应提示，也可从项目 Releases 页面手动下载。

## 从源码运行

```bash
git clone https://github.com/trah01/keepinput.git
cd keepinput
open lockinput.xcodeproj
```

在 Xcode 中选择 `lockinput` scheme 后运行。

## 构建发布包

如果 `xcodebuild` 当前指向 Command Line Tools，需要切换到完整 Xcode：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

构建 Release app：

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

生成 DMG：

```bash
./scripts/create-dmg.sh
```

生成的文件为：

```text
InputLock-1.3.dmg
```

## 自动编译与发布

工作流位于 [.github/workflows/release.yml](.github/workflows/release.yml)，支持两种触发方式：

- 推送版本标签，例如 `v1.3`、`v1.3.1`。
- 在 GitHub 的 Actions → Build and Release → Run workflow 中选择分支或标签，填写版本号；手动触发接受 `v1.3` 或 `1.3`。已有标签会自动检出该标签对应的代码，用于重新编译和上传安装包。

工作流编译 Apple Silicon 与 Intel 通用应用，采用 ad-hoc 签名，生成 `InputLock-<版本>.dmg` 和 `.sha256` 校验文件，并发布到同名 GitHub Release。应用内版本号取自标签，不含 `v` 前缀；手动发布新版本时会创建对应标签。无需配置 Apple 开发者证书，安装包不经过公证。

## 项目结构

```text
lockinput/
├── lockinputApp.swift        # 应用入口与菜单栏
├── ContentView.swift         # 主面板 UI
├── SettingsView.swift        # 设置窗口 UI
├── InputMethodManager.swift  # 输入法读取、切换和锁定逻辑
├── InputSourceLockState.swift # 锁定状态模型
├── GlobalShortcutManager.swift # 快捷键录制和全局触发
├── ApplicationSettings.swift # 菜单栏图标和系统登录项
├── UpdateManager.swift       # 版本检查、下载和重启更新
├── LanguageManager.swift     # 运行时语言切换
├── Info.plist                # 应用元数据
├── Assets.xcassets/          # 图标和资源
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # 简体中文
    ├── fr.lproj/             # Français
    ├── de.lproj/             # Deutsch
    └── ja.lproj/             # 日本語
```

## 本地化

新增语言时：

1. 在 `lockinput/Resources/` 下创建新的 `.lproj` 目录。
2. 复制现有 `Localizable.strings` 并翻译。
3. 在 `lockinput.xcodeproj/project.pbxproj` 的 `knownRegions` 中加入语言代码。
4. 在 `LanguageManager.swift` 的 `AppLanguage` 中加入对应枚举值。

## 许可证

当前仓库尚未包含单独的 `LICENSE` 文件。
