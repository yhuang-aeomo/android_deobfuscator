# Android De-obfuscator

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.5.0+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.5.0+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Desktop%20%7C%20Mobile-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
</p>

一款基于 Flutter 开发的 Android 代码反混淆工具，用于将混淆后的堆栈跟踪（Stack Trace）还原为可读的原始代码信息。支持解析 ProGuard 和 R8 生成的 mapping 文件。

## ✨ 核心功能

- **📁 Mapping 文件解析**
  - 支持标准 ProGuard/R8 mapping 文件格式
  - 拖拽上传或点击选择文件
  - 异步解析，不阻塞 UI 线程
  - 支持大型 mapping 文件（使用 Isolate 后台处理）

- **🔍 智能堆栈跟踪还原**
  - 自动识别混淆的类名和方法名
  - 精确匹配行号映射
  - 实时反混淆预览
  - 支持多行堆栈跟踪批量处理

- **💎 现代化用户界面**
  - Material Design 3 设计语言
  - 响应式布局，适配桌面和移动设备
  - 优雅的拖拽交互体验
  - 深色/浅色主题支持

- **⚡ 高性能处理**
  - 使用 Dart Isolate 进行后台计算
  - 快速映射表构建和查询
  - 实时反馈处理进度

## 🎯 使用场景

- **崩溃日志分析**：快速定位生产环境中的崩溃问题
- **bug 调试**：将用户反馈的混淆堆栈还原为可读信息
- **安全分析**：理解混淆后的代码执行流程
- **持续集成**：集成到 CI/CD 流程中自动化处理崩溃日志

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.5.0 或更高版本
- Dart SDK: 3.5.0 或更高版本

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/yourusername/android_deobfuscator.git
   cd android_deobfuscator
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   
   **Web 平台:**
   ```bash
   flutter run -d chrome
   ```
   
   **桌面平台 (macOS):**
   ```bash
   flutter run -d macos
   ```
   
   **桌面平台 (Windows):**
   ```bash
   flutter run -d windows
   ```
   
   **桌面平台 (Linux):**
   ```bash
   flutter run -d linux
   ```

### 构建发布版本

**构建 Web 应用:**
```bash
flutter build web --release
```

**构建桌面应用 (macOS):**
```bash
flutter build macos --release
```

**构建桌面应用 (Windows):**
```bash
flutter build windows --release
```

## 📖 使用指南

### 1. 上传 Mapping 文件

在左侧面板，通过以下方式上传您的 mapping 文件：
- **拖拽方式**：直接将 mapping.txt 文件拖入上传区域
- **点击选择**：点击上传区域，从文件浏览器中选择文件

### 2. 输入混淆的堆栈跟踪

在左侧的文本输入区域，粘贴您的混淆堆栈跟踪，例如：

```
at com.example.a.b.c(SourceFile:123)
at com.example.d.e.f(Unknown Source)
at android.app.ActivityThread.main(ActivityThread.java:7656)
```

### 3. 查看还原结果

右侧面板会自动显示还原后的堆栈跟踪：

```
at com.example.myapp.MainActivity.onCreate(MainActivity.java:45)
at com.example.myapp.utils.NetworkHelper.fetchData(NetworkHelper.java:89)
at android.app.ActivityThread.main(ActivityThread.java:7656)
```

## 🏗️ 项目结构

```
lib/
├── main.dart                      # 应用入口
├── logic/
│   ├── mapping_processor.dart     # Mapping 文件解析和反混淆核心逻辑
│   └── models.dart                # 数据模型定义
└── ui/
    ├── home_page.dart             # 主页面
    └── widgets/
        ├── mapping_drop_zone.dart # Mapping 文件上传组件
        ├── stack_trace_input.dart # 堆栈跟踪输入组件
        └── retrace_result.dart    # 反混淆结果显示组件
```

## 🛠️ 技术栈

- **框架**: Flutter 3.5.0+
- **语言**: Dart 3.5.0+
- **UI 设计**: Material Design 3
- **状态管理**: StatefulWidget
- **异步处理**: Dart Isolate (Compute)
- **文件选择**: file_picker ^10.3.8
- **拖拽上传**: desktop_drop ^0.7.0

## 📝 Mapping 文件格式说明

本工具支持标准的 ProGuard/R8 mapping 文件格式。典型的 mapping 文件格式如下：

```
com.example.myapp.MainActivity -> com.example.a.b.c:
    10:20:void onCreate(android.os.Bundle):30:40 -> a
    void onResume() -> b
    java.lang.String userName -> d
```

**格式说明:**
- 类映射：`原始类名 -> 混淆类名:`
- 方法映射：`[行号范围:]返回类型 方法名(参数)[:原始行号范围] -> 混淆方法名`
- 字段映射：`类型 字段名 -> 混淆字段名`

## 🔧 核心算法

### Mapping 解析

1. 按行解析 mapping 文件
2. 识别类映射和成员映射
3. 构建快速查找的哈希映射表
4. 支持方法重载和行号精确匹配

### 堆栈跟踪还原

1. 使用正则表达式匹配堆栈跟踪行
2. 提取混淆的类名、方法名和行号
3. 在映射表中查找对应的原始信息
4. 根据行号范围精确匹配方法（处理重载）
5. 重构堆栈跟踪输出

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [ProGuard](https://www.guardsquare.com/proguard) - Android 代码混淆工具
- [R8](https://developer.android.com/studio/build/shrink-code) - Android 官方代码优化工具

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/yourusername/android_deobfuscator/issues)
- 邮件: your.email@example.com

---

<p align="center">
Made with ❤️ using Flutter
</p>
