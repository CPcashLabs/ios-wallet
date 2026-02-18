# iOS Wallet(CPcash)

## 📱 Project Overview

This is a Swift-based iOS cryptocurrency wallet application that supports multi-chain wallet management, transaction signing, NFT display, and more. The project adopts a modern Monorepo structure, built with SwiftUI for iOS 17+ applications, while providing CLI tools for development and testing.

### Key Features
- 🔒 **Secure Account Management**: Support for EVM chain signing and Passkey login
- 💱 **Multi-Chain Support**: BSC, Polygon, TRON, and EVM-compatible networks
- 🌐 **DApp Integration**: Interact with DApps through the EIP-1193 protocol
- 📊 **Transaction History**: View transaction records and bills
- 💳 **Send & Receive**: Quick and convenient asset transfer functionality

---

## 📁 Project Structure

### Core Applications
- **`apps/ios/AppShelliOS`** - iOS 17+ SwiftUI main application (generated using xcodegen)
- **`apps/cli/AppShell`** - Command-line tool for development debugging and automated testing

### Core Libraries
- **`packages/CoreRuntime`** - Module runtime, routing, permission management, confirmation flow framework
- **`packages/SecurityCore`** - Security core library (EVM signing, transaction broadcasting, key management)
- **`packages/BackendAPI`** - Backend API encapsulation and data models
- **`packages/WebDAppContainer`** - WKWebView and DApp EIP-1193 bridge implementation

### Business Modules
- **`modules/NftGallery`** - NFT display module example

### Tools
- **`tools/ModuleRegistryPlugin`** - Automatic module registration generation tool

### Compatibility Paths (Retained)
```
AppShelliOS -> apps/ios/AppShelliOS
AppShell -> apps/cli/AppShell
Packages -> packages
Modules -> modules
Tools -> tools
```

---

## 🚀 Quick Start

### Requirements
- macOS 12+
- Xcode 15+
- Swift 5.9+

### Running the CLI Tool
```bash
swift run AppShell
```

### Building iOS Application (Simulator)
```bash
cd apps/ios/AppShelliOS

# Generate Xcode project
xcodegen generate

# Build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project AppShelliOS.xcodeproj \
  -scheme AppShelliOS \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/AppShelliOSDerived \
  CODE_SIGNING_ALLOWED=NO build
```

### Opening the Project in Xcode
```bash
cd apps/ios/AppShelliOS
open AppShelliOS.xcodeproj
```

---

## 📊 Development Progress

### Phase 1 - Foundation Framework ✅
- Runnable application skeleton
- Modular architecture setup

### Phase A - EVM Security Features 🔄
- Real EVM signing implementation
- Complete transaction flow integration

### Phase B - Core Feature Iteration 🔄
- Passkey login integration
- Home, receive, and transfer features
- Transaction history and profile pages

---

## 🏗️ Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum OS**: iOS 17+
- **Cryptography**: SecurityCore (EVM signing)
- **Networking**: URLSession + Backend API
- **DApp Communication**: WKWebView + EIP-1193 protocol

---

## 📝 Development Guide

### Adding a New Module

1. Create a new module folder in the `modules/` directory
2. Implement a `*Manifest.swift` file to define module information
3. Run the module registration generation tool to update `ModuleRegistry.swift`

### Project Configuration

- **iOS Project Configuration**: `apps/ios/AppShelliOS/project.yml`
- **Swift Package Configuration**: `Package.swift`

---

## 📦 Dependency Management

Dependencies are managed through Swift Package Manager. For details, run:
```bash
cat Package.swift
cat Package.resolved
```

---

## 💡 Important Notes

- Use `Makefile` to quickly execute common tasks
- Simulator builds require code signing to be disabled (`CODE_SIGNING_ALLOWED=NO`)
- Ensure Xcode is pointing to the correct Developer directory
