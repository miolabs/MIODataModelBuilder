import SwiftUI
import UniformTypeIdentifiers
import AppKit

@main
struct CoreDataModelEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        DocumentGroup(newDocument: CoreDataModelDocument()) { file in
            ContentView(document: file.document)
                .frame(minWidth: 1000, minHeight: 600)
                .toolbar(id: "mainToolbar") {
                    ToolbarItemGroup(placement: .navigation) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "sidebar.left")
                        }
                        .help("Toggle Sidebar")
                    }
                }
        }
        .commands {
            SidebarCommands()
            
            CommandGroup(after: .newItem) {
                Button("New Entity") {
                    if let document = NSApp.keyWindow?.windowController?.document as? CoreDataModelDocument {
                        // Simply add entity with default name, ContentView will handle selection
                        _ = document.addEntity(name: "NewEntity")
                    }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Button("New Attribute") {
                    if let document = NSApp.keyWindow?.windowController?.document as? CoreDataModelDocument,
                       let selectedEntity = document.model.entities.first {
                        // Add attribute to first entity if no selection
                        document.addAttribute(to: selectedEntity, name: "newAttribute", type: .string)
                    }
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                
                Button("New Relationship") {
                    if let document = NSApp.keyWindow?.windowController?.document as? CoreDataModelDocument,
                       let selectedEntity = document.model.entities.first {
                        // Add relationship to first entity if no selection
                        // Default to first entity as destination
                        let destinationEntityName = document.model.entities.first?.name ?? selectedEntity.name
                        document.addRelationship(to: selectedEntity, name: "newRelationship", destinationEntity: destinationEntityName)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .saveItem) {
                Button("Add Version...") {
                    if let document = NSApp.keyWindow?.windowController?.document as? CoreDataModelDocument {
                        // Show dialog to get version name
                        let alert = NSAlert()
                        alert.messageText = "New Model Version"
                        alert.informativeText = "Enter a name for the new version:"
                        
                        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
                        textField.placeholderString = "Version Name"
                        alert.accessoryView = textField
                        
                        alert.addButton(withTitle: "Create")
                        alert.addButton(withTitle: "Cancel")
                        
                        if alert.runModal() == .alertFirstButtonReturn {
                            let versionName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !versionName.isEmpty {
                                _ = document.createNewVersion(name: versionName)
                            }
                        }
                    }
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// App Delegate to handle menu actions
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup code if needed
    }
}

// Simple settings view
struct SettingsView: View {
    var body: some View {
        Form {
            Text("Core Data Model Editor Settings")
                .font(.title)
                .padding(.bottom)
            
            Text("No settings available yet.")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
