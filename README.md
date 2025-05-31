# Core Data Model Editor

A native macOS application built with SwiftUI that lets you **open, inspect, edit and save** Apple Core Data models (`.xcdatamodeld`) outside of Xcode.  
It reproduces— and in some areas extends— the familiar Xcode Data Model inspector with a clean **four-panel layout**:

1. **File Explorer** – browse model packages & versions  
2. **Entities List** – quick overview of entities  
3. **Entity Detail** – attributes, relationships & fetched properties tables  
4. **Property Inspector** – contextual editor for the selected item  

Multiple models can be open at once using a tabbed interface, and full read/write support means the changes you make are compatible with Xcode and your build pipeline.

---

## ✨ Features
- Open any `.xcdatamodeld` package (supports versioned models)
- Edit entities, attributes, relationships, fetched properties & configurations
- Add / rename / delete model versions and switch the current version
- Undo & Redo with deep model awareness
- Multi-tab workspace to work on several models simultaneously
- XML persistence via [XMLCoder](https://github.com/MaxDesiatov/XMLCoder) – output identical to Xcode
- Keyboard shortcuts for common actions (`⌘⇧E` new entity, `⌘⇧A` new attribute, `⌘⇧R` new relationship, `⌘⇧V` new version)
- Native macOS look & feel (dark-mode, sidebar, toolbar, menu commands)

---

## 🖥 System Requirements
|                     | Minimum |
|---------------------|---------|
| macOS               | 12.0 (Monterey) |
| Xcode               | 15 or later |
| Swift               | 5.7 |
| Architecture        | Apple Silicon & Intel (Universal) |

---

## 🛠 Building & Running

### Via Xcode (recommended)
```bash
git clone https://github.com/your-org/CoreDataModelEditor.git
open CoreDataModelEditor/Package.swift
```
1. Select the *CoreDataModelEditor* scheme  
2. Choose *My Mac* as the run destination  
3. ⌘R to build & launch

### Via Swift Package Manager CLI
```bash
swift run
```

---

## 🚀 Usage Guide

| Step | Action |
|------|--------|
| 1    | **File ▸ Open…** or **⌘O** and choose an `.xcdatamodeld` package |
| 2    | Use the **File Explorer** (far left) to pick a model version or add a new one |
| 3    | Select an entity in the **Entities List** to reveal its details |
| 4    | Switch between **Attributes / Relationships / Fetched Properties** tabs to edit tables |
| 5    | Click any row, then refine values in the **Property Inspector** |
| 6    | **⌘S** to save – XML is written back into the package, Xcode sees the changes instantly |

Tip: right-click lists or use toolbar buttons for *Add* / *Delete* actions.

---

## 🏗 Architecture Overview

```
SwiftUI App ⟶ Document-based (CoreDataModelDocument)
           ⟶ MVVM layer (ObservableObject models)
           ⟶ XML Parsing / Encoding (XMLCoder)
```

### Core Layers
| Layer | Responsibility |
|-------|----------------|
| **Models** | Pure Swift structs/classes mirroring Core Data concepts (`CDEntity`, `CDAttribute`, …) |
| **Persistence** | `CoreDataModelDocument` converts between models and `XMLModel` (the on-disk schema) and handles version packages |
| **Views** | Modular SwiftUI views for each panel; state propagated via `@ObservedObject` & `@StateObject` |
| **Commands** | App / toolbar / context menus wired to document mutation helpers with Undo support |

This separation keeps UI reactive while ensuring XML files stay 100 % compatible with Xcode.

---

## 🤝 Contributing

Contributions are welcome!  
1. Fork the repo & create a feature branch (`git checkout -b feature/your-feature`)  
2. Follow the existing **SwiftLint** style (run `swiftlint --fix`)  
3. Write unit tests in `CoreDataModelEditorTests` for all new logic  
4. Submit a pull request describing **what** and **why**

Please open an issue first if you plan a large change— we’d love to discuss design direction.

---

## 📝 License

`Core Data Model Editor` is released under the MIT License.  
See the `LICENSE` file for details.

