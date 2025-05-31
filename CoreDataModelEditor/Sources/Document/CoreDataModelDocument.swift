import SwiftUI
import UniformTypeIdentifiers
import XMLCoder
import Combine

class CoreDataModelDocument: FileDocument, ObservableObject {
    // MARK: - Properties
    
    // The main data model
    @Published var model: CoreDataModel
    
    // All versions of the model in the package
    @Published var versions: [String: CoreDataModel] = [:]
    
    // Current version name
    @Published var currentVersionName: String = ""
    
    // Undo manager
    private var undoManager = UndoManager()
    
    // File path
    private var modelPackagePath: URL?
    
    // Track if the document has been modified
    @Published var isModified: Bool = false
    
    // MARK: - FileDocument Protocol
    
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "xcdatamodeld")!]
    }
    
    // Default initializer for new documents
    init() {
        self.model = CoreDataModel(name: "Untitled")
        self.currentVersionName = "Untitled"
        self.versions = ["Untitled": self.model]
        setupUndoRedoObservation()
    }
    
    // Initialize from file data
    required init(configuration: ReadConfiguration) throws {
        guard let fileWrapper = configuration.file else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // xcdatamodeld is a directory package
        guard fileWrapper.isDirectory else {
            throw CocoaError(.fileReadUnknown, userInfo: [NSLocalizedDescriptionKey: "Not a valid Core Data model package."])
        }
        
        // Get package name (without extension)
        let packageName = configuration.contentType.preferredFilename?.components(separatedBy: ".").first ?? "Untitled"
        
        // Initialize with empty model
        self.model = CoreDataModel(name: packageName)
        
        // Load all model versions from the package
        var allVersions: [String: CoreDataModel] = [:]
        var currentVersion: String = ""
        
        // Parse the .xcdatamodeld directory to find all model versions
        for (name, versionWrapper) in fileWrapper.fileWrappers ?? [:] {
            // Each version is a directory with a .xcdatamodel extension
            if name.hasSuffix(".xcdatamodel") && versionWrapper.isDirectory {
                // Extract version name (without extension)
                let versionName = name.components(separatedBy: ".").first ?? name
                
                // Look for the contents file in the version directory
                if let contentsWrapper = versionWrapper.fileWrappers?["contents"] {
                    if let contentsData = contentsWrapper.regularFileContents {
                        // Parse the XML contents
                        let decoder = XMLDecoder()
                        do {
                            let xmlModel = try decoder.decode(XMLModel.self, from: contentsData)
                            let coreDataModel = CoreDataModel.from(xmlModel: xmlModel)
                            coreDataModel.name = versionName
                            allVersions[versionName] = coreDataModel
                            
                            // Check if this is the current version
                            if let currentModelVersionData = versionWrapper.fileWrappers?[".xccurrentversion"]?.regularFileContents,
                               let currentVersionDict = try? PropertyListSerialization.propertyList(from: currentModelVersionData, options: [], format: nil) as? [String: Any],
                               let currentVersionPath = currentVersionDict["_XCCurrentVersionName"] as? String {
                                if currentVersionPath == name {
                                    currentVersion = versionName
                                }
                            }
                        } catch {
                            print("Error decoding model version \(versionName): \(error)")
                        }
                    }
                }
            }
        }
        
        // If we found versions, use them
        if !allVersions.isEmpty {
            self.versions = allVersions
            
            // If we identified the current version, use it
            if !currentVersion.isEmpty {
                self.currentVersionName = currentVersion
                if let model = allVersions[currentVersion] {
                    self.model = model
                }
            } else if let firstVersion = allVersions.keys.sorted().first, let model = allVersions[firstVersion] {
                // Otherwise use the first version alphabetically
                self.currentVersionName = firstVersion
                self.model = model
            }
        }
        
        // Store the file path for later use
        if let url = configuration.file.filename {
            self.modelPackagePath = URL(fileURLWithPath: url)
        }
        
        setupUndoRedoObservation()
    }
    
    // Write the document back to file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create a directory wrapper for the .xcdatamodeld package
        let packageWrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        // Save each version
        for (versionName, versionModel) in versions {
            // Create a directory for this version
            let versionWrapper = FileWrapper(directoryWithFileWrappers: [:])
            
            // Convert the model to XML
            let xmlModel = versionModel.toXMLModel()
            let encoder = XMLEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            
            do {
                let xmlData = try encoder.encode(xmlModel, withRootKey: "model")
                
                // Create the contents file
                let contentsWrapper = FileWrapper(regularFileWithContents: xmlData)
                versionWrapper.addFileWrapper(contentsWrapper)
                contentsWrapper.preferredFilename = "contents"
                
                // Add the version directory to the package
                packageWrapper.addFileWrapper(versionWrapper)
                versionWrapper.preferredFilename = "\(versionName).xcdatamodel"
            } catch {
                print("Error encoding model version \(versionName): \(error)")
                throw error
            }
        }
        
        // Create the .xccurrentversion file to indicate the current version
        if !currentVersionName.isEmpty, versions.keys.contains(currentVersionName) {
            let currentVersionDict: [String: Any] = [
                "_XCCurrentVersionName": "\(currentVersionName).xcdatamodel"
            ]
            
            if let currentVersionData = try? PropertyListSerialization.data(fromPropertyList: currentVersionDict, format: .xml, options: 0) {
                let currentVersionWrapper = FileWrapper(regularFileWithContents: currentVersionData)
                packageWrapper.addFileWrapper(currentVersionWrapper)
                currentVersionWrapper.preferredFilename = ".xccurrentversion"
            }
        }
        
        return packageWrapper
    }
    
    // MARK: - Version Management
    
    // Switch to a different version
    func switchToVersion(_ versionName: String) {
        if let versionModel = versions[versionName] {
            self.currentVersionName = versionName
            self.model = versionModel
        }
    }
    
    // Create a new version
    func createNewVersion(name: String, basedOn sourceVersionName: String? = nil) -> Bool {
        // Check if the version name already exists
        if versions.keys.contains(name) {
            return false
        }
        
        // Create a new model based on the specified source or current model
        var newModel: CoreDataModel
        if let sourceVersionName = sourceVersionName, let sourceModel = versions[sourceVersionName] {
            // Deep copy the source model
            newModel = deepCopy(sourceModel)
        } else {
            // Deep copy the current model
            newModel = deepCopy(model)
        }
        
        // Update the new model's name
        newModel.name = name
        
        // Add the new version
        versions[name] = newModel
        
        // Switch to the new version
        switchToVersion(name)
        
        return true
    }
    
    // Rename a version
    func renameVersion(from oldName: String, to newName: String) -> Bool {
        // Check if the old version exists and the new name doesn't
        guard versions.keys.contains(oldName), !versions.keys.contains(newName) else {
            return false
        }
        
        // Get the model
        guard let versionModel = versions[oldName] else {
            return false
        }
        
        // Update the model name
        versionModel.name = newName
        
        // Add with new name and remove old entry
        versions[newName] = versionModel
        versions.removeValue(forKey: oldName)
        
        // Update current version name if needed
        if currentVersionName == oldName {
            currentVersionName = newName
        }
        
        return true
    }
    
    // Delete a version
    func deleteVersion(_ versionName: String) -> Bool {
        // Check if the version exists and it's not the only one
        guard versions.keys.contains(versionName), versions.count > 1 else {
            return false
        }
        
        // Remove the version
        versions.removeValue(forKey: versionName)
        
        // If we deleted the current version, switch to another one
        if currentVersionName == versionName {
            if let firstVersion = versions.keys.sorted().first {
                switchToVersion(firstVersion)
            }
        }
        
        return true
    }
    
    // MARK: - Undo/Redo Support
    
    // Get the undo manager
    var documentUndoManager: UndoManager {
        return undoManager
    }
    
    // Register an undo operation
    func registerUndo<T>(for property: ReferenceWritableKeyPath<CoreDataModel, T>, oldValue: T, newValue: T) {
        undoManager.registerUndo(withTarget: self) { document in
            document.model[keyPath: property] = oldValue
            document.registerUndo(for: property, oldValue: newValue, newValue: oldValue)
        }
        isModified = true
    }
    
    // Register an entity undo operation
    func registerEntityUndo<T>(entityId: UUID, for property: ReferenceWritableKeyPath<CDEntity, T>, oldValue: T, newValue: T) {
        guard let entity = findEntity(withId: entityId) else { return }
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entityId) {
                entity[keyPath: property] = oldValue
                document.registerEntityUndo(entityId: entityId, for: property, oldValue: newValue, newValue: oldValue)
            }
        }
        isModified = true
    }
    
    // Register an attribute undo operation
    func registerAttributeUndo<T>(entityId: UUID, attributeId: UUID, for property: ReferenceWritableKeyPath<CDAttribute, T>, oldValue: T, newValue: T) {
        guard let entity = findEntity(withId: entityId),
              let attribute = entity.attributes.first(where: { $0.id == attributeId }) else { return }
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entityId),
               let attribute = entity.attributes.first(where: { $0.id == attributeId }) {
                attribute[keyPath: property] = oldValue
                document.registerAttributeUndo(entityId: entityId, attributeId: attributeId, for: property, oldValue: newValue, newValue: oldValue)
            }
        }
        isModified = true
    }
    
    // Register a relationship undo operation
    func registerRelationshipUndo<T>(entityId: UUID, relationshipId: UUID, for property: ReferenceWritableKeyPath<CDRelationship, T>, oldValue: T, newValue: T) {
        guard let entity = findEntity(withId: entityId),
              let relationship = entity.relationships.first(where: { $0.id == relationshipId }) else { return }
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entityId),
               let relationship = entity.relationships.first(where: { $0.id == relationshipId }) {
                relationship[keyPath: property] = oldValue
                document.registerRelationshipUndo(entityId: entityId, relationshipId: relationshipId, for: property, oldValue: newValue, newValue: oldValue)
            }
        }
        isModified = true
    }
    
    // MARK: - Helper Methods
    
    // Find an entity by ID
    private func findEntity(withId id: UUID) -> CDEntity? {
        return model.entities.first { $0.id == id }
    }
    
    // Deep copy a model (for version creation)
    private func deepCopy(_ model: CoreDataModel) -> CoreDataModel {
        // In a real implementation, we'd do a proper deep copy
        // For now, we'll use JSON encoding/decoding as a simple way to deep copy
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(model)
            return try decoder.decode(CoreDataModel.self, from: data)
        } catch {
            print("Error deep copying model: \(error)")
            // Fallback to a simple copy
            return CoreDataModel(
                name: model.name,
                entities: model.entities,
                configurations: model.configurations,
                version: model.version,
                currentVersion: model.currentVersion
            )
        }
    }
    
    // Setup observation for undo/redo
    private func setupUndoRedoObservation() {
        // In a real implementation, we'd use Combine to observe changes to the model
        // and register undo operations automatically
    }
    
    // MARK: - Model Manipulation
    
    // Add a new entity
    func addEntity(name: String) -> CDEntity {
        let entity = model.addEntity(name: name)
        
        undoManager.registerUndo(withTarget: self) { document in
            document.model.removeEntity(entity)
            document.isModified = true
        }
        
        isModified = true
        return entity
    }
    
    // Remove an entity
    func removeEntity(_ entity: CDEntity) {
        // Store the entity for undo
        let entityIndex = model.entities.firstIndex { $0.id == entity.id }
        
        model.removeEntity(entity)
        
        if let index = entityIndex {
            undoManager.registerUndo(withTarget: self) { document in
                document.model.entities.insert(entity, at: min(index, document.model.entities.count))
                document.isModified = true
            }
        }
        
        isModified = true
    }
    
    // Add an attribute to an entity
    func addAttribute(to entity: CDEntity, name: String, type: CDAttributeType) -> CDAttribute {
        let attribute = entity.addAttribute(name: name, type: type)
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entity.id) {
                entity.removeAttribute(attribute)
                document.isModified = true
            }
        }
        
        isModified = true
        return attribute
    }
    
    // Remove an attribute from an entity
    func removeAttribute(_ attribute: CDAttribute, from entity: CDEntity) {
        // Store the attribute for undo
        let attributeIndex = entity.attributes.firstIndex { $0.id == attribute.id }
        
        entity.removeAttribute(attribute)
        
        if let index = attributeIndex {
            undoManager.registerUndo(withTarget: self) { document in
                if let entity = document.findEntity(withId: entity.id) {
                    entity.attributes.insert(attribute, at: min(index, entity.attributes.count))
                    document.isModified = true
                }
            }
        }
        
        isModified = true
    }
    
    // Add a relationship to an entity
    func addRelationship(to entity: CDEntity, name: String, destinationEntity: String) -> CDRelationship {
        let relationship = entity.addRelationship(name: name, destinationEntity: destinationEntity)
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entity.id) {
                entity.removeRelationship(relationship)
                document.isModified = true
            }
        }
        
        isModified = true
        return relationship
    }
    
    // Remove a relationship from an entity
    func removeRelationship(_ relationship: CDRelationship, from entity: CDEntity) {
        // Store the relationship for undo
        let relationshipIndex = entity.relationships.firstIndex { $0.id == relationship.id }
        
        entity.removeRelationship(relationship)
        
        if let index = relationshipIndex {
            undoManager.registerUndo(withTarget: self) { document in
                if let entity = document.findEntity(withId: entity.id) {
                    entity.relationships.insert(relationship, at: min(index, entity.relationships.count))
                    document.isModified = true
                }
            }
        }
        
        isModified = true
    }
    
    // Add a fetched property to an entity
    func addFetchedProperty(to entity: CDEntity, name: String, predicate: String) -> CDFetchedProperty {
        let fetchedProperty = entity.addFetchedProperty(name: name, predicate: predicate)
        
        undoManager.registerUndo(withTarget: self) { document in
            if let entity = document.findEntity(withId: entity.id) {
                entity.removeFetchedProperty(fetchedProperty)
                document.isModified = true
            }
        }
        
        isModified = true
        return fetchedProperty
    }
    
    // Remove a fetched property from an entity
    func removeFetchedProperty(_ fetchedProperty: CDFetchedProperty, from entity: CDEntity) {
        // Store the fetched property for undo
        let fetchedPropertyIndex = entity.fetchedProperties.firstIndex { $0.id == fetchedProperty.id }
        
        entity.removeFetchedProperty(fetchedProperty)
        
        if let index = fetchedPropertyIndex {
            undoManager.registerUndo(withTarget: self) { document in
                if let entity = document.findEntity(withId: entity.id) {
                    entity.fetchedProperties.insert(fetchedProperty, at: min(index, entity.fetchedProperties.count))
                    document.isModified = true
                }
            }
        }
        
        isModified = true
    }
    
    // Add a configuration
    func addConfiguration(name: String) -> CDConfiguration {
        let configuration = model.addConfiguration(name: name)
        
        undoManager.registerUndo(withTarget: self) { document in
            document.model.removeConfiguration(configuration)
            document.isModified = true
        }
        
        isModified = true
        return configuration
    }
    
    // Remove a configuration
    func removeConfiguration(_ configuration: CDConfiguration) {
        // Store the configuration for undo
        let configurationIndex = model.configurations.firstIndex { $0.id == configuration.id }
        
        model.removeConfiguration(configuration)
        
        if let index = configurationIndex {
            undoManager.registerUndo(withTarget: self) { document in
                document.model.configurations.insert(configuration, at: min(index, document.model.configurations.count))
                document.isModified = true
            }
        }
        
        isModified = true
    }
}
