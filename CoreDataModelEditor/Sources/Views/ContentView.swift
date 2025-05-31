import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var document: CoreDataModelDocument
    @StateObject private var selectionState = SelectionState()
    
    // Minimum widths for each panel
    private let fileExplorerMinWidth: CGFloat = 200
    private let entitiesListMinWidth: CGFloat = 200
    private let entityDetailMinWidth: CGFloat = 300
    private let propertyInspectorMinWidth: CGFloat = 250
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area
            HStack {
                Button(action: addEntity) {
                    Label("Add Entity", systemImage: "plus.square")
                }
                Button(action: addAttribute) {
                    Label("Add Attribute", systemImage: "plus.circle")
                        .disabled(selectionState.selectedEntityId == nil)
                }
                Button(action: addRelationship) {
                    Label("Add Relationship", systemImage: "arrow.triangle.branch")
                        .disabled(selectionState.selectedEntityId == nil)
                }
                Spacer()
                
                // Version management
                if !document.versions.isEmpty {
                    Picker("Version", selection: $document.currentVersionName) {
                        ForEach(Array(document.versions.keys.sorted()), id: \.self) { versionName in
                            Text(versionName).tag(versionName)
                        }
                    }
                    .frame(width: 200)
                    
                    Button(action: addVersion) {
                        Label("New Version", systemImage: "plus.rectangle.on.folder")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Main 4-panel layout
            HSplitView {
                // File Explorer Panel (far left)
                FileExplorerView(document: document)
                    .frame(minWidth: fileExplorerMinWidth)
                
                // Entities List Panel (left-center)
                EntitiesListView(
                    entities: document.model.entities,
                    selectedEntityId: $selectionState.selectedEntityId,
                    onAddEntity: addEntity,
                    onDeleteEntity: deleteEntity
                )
                .frame(minWidth: entitiesListMinWidth)
                
                // Attributes/Relationships Table Panel (right-center)
                EntityDetailView(
                    document: document,
                    entityId: selectionState.selectedEntityId,
                    selectedAttributeId: $selectionState.selectedAttributeId,
                    selectedRelationshipId: $selectionState.selectedRelationshipId,
                    selectedFetchedPropertyId: $selectionState.selectedFetchedPropertyId,
                    selectedTab: $selectionState.selectedDetailTab,
                    onAddAttribute: { addAttribute() },
                    onAddRelationship: { addRelationship() },
                    onAddFetchedProperty: { addFetchedProperty() }
                )
                .frame(minWidth: entityDetailMinWidth)
                
                // Property Inspector Panel (far right)
                PropertyInspectorView(
                    document: document,
                    selectionState: selectionState
                )
                .frame(minWidth: propertyInspectorMinWidth)
            }
        }
        .onAppear {
            // Reset selection when view appears
            selectionState.reset()
        }
        .onChange(of: document.currentVersionName) { _ in
            // Reset selection when version changes
            selectionState.reset()
        }
    }
    
    // MARK: - Actions
    
    private func addEntity() {
        let newEntityName = "NewEntity"
        let entity = document.addEntity(name: newEntityName)
        selectionState.selectedEntityId = entity.id
        selectionState.selectedAttributeId = nil
        selectionState.selectedRelationshipId = nil
        selectionState.selectedFetchedPropertyId = nil
    }
    
    private func deleteEntity() {
        guard let entityId = selectionState.selectedEntityId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return
        }
        
        document.removeEntity(entity)
        selectionState.selectedEntityId = nil
        selectionState.selectedAttributeId = nil
        selectionState.selectedRelationshipId = nil
        selectionState.selectedFetchedPropertyId = nil
    }
    
    private func addAttribute() {
        guard let entityId = selectionState.selectedEntityId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return
        }
        
        let newAttributeName = "newAttribute"
        let attribute = document.addAttribute(to: entity, name: newAttributeName, type: .string)
        selectionState.selectedAttributeId = attribute.id
        selectionState.selectedRelationshipId = nil
        selectionState.selectedFetchedPropertyId = nil
        selectionState.selectedDetailTab = .attributes
    }
    
    private func addRelationship() {
        guard let entityId = selectionState.selectedEntityId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return
        }
        
        // Default to first entity other than current one, or self if no other entities
        var destinationEntityName = entity.name
        if let otherEntity = document.model.entities.first(where: { $0.id != entityId }) {
            destinationEntityName = otherEntity.name
        }
        
        let newRelationshipName = "newRelationship"
        let relationship = document.addRelationship(to: entity, name: newRelationshipName, destinationEntity: destinationEntityName)
        selectionState.selectedAttributeId = nil
        selectionState.selectedRelationshipId = relationship.id
        selectionState.selectedFetchedPropertyId = nil
        selectionState.selectedDetailTab = .relationships
    }
    
    private func addFetchedProperty() {
        guard let entityId = selectionState.selectedEntityId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return
        }
        
        let newFetchedPropertyName = "newFetchedProperty"
        let fetchedProperty = document.addFetchedProperty(to: entity, name: newFetchedPropertyName, predicate: "TRUEPREDICATE")
        selectionState.selectedAttributeId = nil
        selectionState.selectedRelationshipId = nil
        selectionState.selectedFetchedPropertyId = fetchedProperty.id
        selectionState.selectedDetailTab = .fetchedProperties
    }
    
    private func addVersion() {
        // Show a dialog to get the new version name
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

// MARK: - Selection State

class SelectionState: ObservableObject {
    // Entity selection
    @Published var selectedEntityId: UUID?
    
    // Detail item selections
    @Published var selectedAttributeId: UUID?
    @Published var selectedRelationshipId: UUID?
    @Published var selectedFetchedPropertyId: UUID?
    
    // Selected detail tab
    @Published var selectedDetailTab: EntityDetailTab = .attributes
    
    // Reset all selections
    func reset() {
        selectedEntityId = nil
        selectedAttributeId = nil
        selectedRelationshipId = nil
        selectedFetchedPropertyId = nil
        selectedDetailTab = .attributes
    }
}

// MARK: - Entity Detail Tabs

enum EntityDetailTab: String, CaseIterable, Identifiable {
    case attributes = "Attributes"
    case relationships = "Relationships"
    case fetchedProperties = "Fetched Properties"
    
    var id: String { self.rawValue }
}

// MARK: - File Explorer View

struct FileExplorerView: View {
    @ObservedObject var document: CoreDataModelDocument
    @State private var isAddingVersion = false
    @State private var newVersionName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MODEL VERSIONS")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: { isAddingVersion = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // List of versions
            List {
                Section {
                    ForEach(Array(document.versions.keys.sorted()), id: \.self) { versionName in
                        HStack {
                            Image(systemName: "cube")
                                .foregroundColor(.blue)
                            
                            Text(versionName)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if versionName == document.currentVersionName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            document.switchToVersion(versionName)
                        }
                    }
                }
                
                Section("Files") {
                    // Placeholder for actual file browser
                    Text("Model Package")
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(SidebarListStyle())
        }
        .sheet(isPresented: $isAddingVersion) {
            VStack(spacing: 20) {
                Text("Create New Version")
                    .font(.headline)
                
                TextField("Version Name", text: $newVersionName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                HStack {
                    Button("Cancel") {
                        isAddingVersion = false
                        newVersionName = ""
                    }
                    
                    Button("Create") {
                        if !newVersionName.isEmpty {
                            _ = document.createNewVersion(name: newVersionName)
                            isAddingVersion = false
                            newVersionName = ""
                        }
                    }
                    .disabled(newVersionName.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top)
            }
            .padding()
            .frame(width: 350, height: 150)
        }
    }
}

// MARK: - Entities List View

struct EntitiesListView: View {
    let entities: [CDEntity]
    @Binding var selectedEntityId: UUID?
    let onAddEntity: () -> Void
    let onDeleteEntity: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("ENTITIES")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: onAddEntity) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // List of entities
            List {
                ForEach(entities, id: \.id) { entity in
                    HStack {
                        Image(systemName: "tablecells")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(entity.name)
                                .fontWeight(entity.isAbstract ? .light : .regular)
                            
                            if let parentEntity = entity.parentEntity {
                                Text(parentEntity)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if entity.isAbstract {
                            Text("Abstract")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(4)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                    .background(entity.id == selectedEntityId ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .onTapGesture {
                        selectedEntityId = entity.id
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first,
                       index < entities.count,
                       entities[index].id == selectedEntityId {
                        onDeleteEntity()
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom toolbar
            HStack {
                Button(action: onAddEntity) {
                    Label("Add", systemImage: "plus")
                }
                
                Spacer()
                
                Button(action: onDeleteEntity) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedEntityId == nil)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
        }
    }
}

// MARK: - Entity Detail View

struct EntityDetailView: View {
    @ObservedObject var document: CoreDataModelDocument
    let entityId: UUID?
    @Binding var selectedAttributeId: UUID?
    @Binding var selectedRelationshipId: UUID?
    @Binding var selectedFetchedPropertyId: UUID?
    @Binding var selectedTab: EntityDetailTab
    let onAddAttribute: () -> Void
    let onAddRelationship: () -> Void
    let onAddFetchedProperty: () -> Void
    
    private var entity: CDEntity? {
        guard let entityId = entityId else { return nil }
        return document.model.entities.first { $0.id == entityId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Entity name header
            if let entity = entity {
                Text(entity.name)
                    .font(.headline)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.controlBackgroundColor))
            } else {
                Text("No Entity Selected")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.controlBackgroundColor))
            }
            
            // Tabs for attributes, relationships, fetched properties
            if entity != nil {
                Picker("", selection: $selectedTab) {
                    ForEach(EntityDetailTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Attributes Tab
                    attributesView
                        .tag(EntityDetailTab.attributes)
                    
                    // Relationships Tab
                    relationshipsView
                        .tag(EntityDetailTab.relationships)
                    
                    // Fetched Properties Tab
                    fetchedPropertiesView
                        .tag(EntityDetailTab.fetchedProperties)
                }
                .tabViewStyle(DefaultTabViewStyle())
            } else {
                // No entity selected
                VStack {
                    Spacer()
                    Text("Select an entity to view its details")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Attributes View
    
    private var attributesView: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Attribute")
                    .fontWeight(.bold)
                    .frame(width: 150, alignment: .leading)
                
                Spacer()
                
                Text("Type")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                
                Spacer()
                
                Text("Optional")
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Table content
            List {
                if let entity = entity {
                    ForEach(entity.attributes, id: \.id) { attribute in
                        HStack {
                            Text(attribute.name)
                                .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            Text(attribute.attributeType.rawValue)
                                .frame(width: 120, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: attribute.isOptional ? "checkmark.square" : "square")
                                .frame(width: 80, alignment: .center)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                        .background(attribute.id == selectedAttributeId ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedAttributeId = attribute.id
                            selectedRelationshipId = nil
                            selectedFetchedPropertyId = nil
                        }
                    }
                    .onDelete { indexSet in
                        deleteAttributes(at: indexSet, from: entity)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom toolbar
            HStack {
                Button(action: onAddAttribute) {
                    Label("Add Attribute", systemImage: "plus")
                }
                
                Spacer()
                
                Button(action: {
                    if let entity = entity, let attributeId = selectedAttributeId {
                        if let attribute = entity.attributes.first(where: { $0.id == attributeId }) {
                            document.removeAttribute(attribute, from: entity)
                            selectedAttributeId = nil
                        }
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedAttributeId == nil)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
        }
    }
    
    // MARK: - Relationships View
    
    private var relationshipsView: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Relationship")
                    .fontWeight(.bold)
                    .frame(width: 150, alignment: .leading)
                
                Spacer()
                
                Text("Destination")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                
                Spacer()
                
                Text("To-Many")
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Table content
            List {
                if let entity = entity {
                    ForEach(entity.relationships, id: \.id) { relationship in
                        HStack {
                            Text(relationship.name)
                                .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            Text(relationship.destinationEntity)
                                .frame(width: 120, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: relationship.isToMany ? "checkmark.square" : "square")
                                .frame(width: 80, alignment: .center)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                        .background(relationship.id == selectedRelationshipId ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedAttributeId = nil
                            selectedRelationshipId = relationship.id
                            selectedFetchedPropertyId = nil
                        }
                    }
                    .onDelete { indexSet in
                        deleteRelationships(at: indexSet, from: entity)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom toolbar
            HStack {
                Button(action: onAddRelationship) {
                    Label("Add Relationship", systemImage: "plus")
                }
                
                Spacer()
                
                Button(action: {
                    if let entity = entity, let relationshipId = selectedRelationshipId {
                        if let relationship = entity.relationships.first(where: { $0.id == relationshipId }) {
                            document.removeRelationship(relationship, from: entity)
                            selectedRelationshipId = nil
                        }
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedRelationshipId == nil)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
        }
    }
    
    // MARK: - Fetched Properties View
    
    private var fetchedPropertiesView: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Fetched Property")
                    .fontWeight(.bold)
                    .frame(width: 150, alignment: .leading)
                
                Spacer()
                
                Text("Predicate")
                    .fontWeight(.bold)
                    .frame(width: 200, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Table content
            List {
                if let entity = entity {
                    ForEach(entity.fetchedProperties, id: \.id) { fetchedProperty in
                        HStack {
                            Text(fetchedProperty.name)
                                .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            Text(fetchedProperty.predicate)
                                .frame(width: 200, alignment: .leading)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                        .background(fetchedProperty.id == selectedFetchedPropertyId ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedAttributeId = nil
                            selectedRelationshipId = nil
                            selectedFetchedPropertyId = fetchedProperty.id
                        }
                    }
                    .onDelete { indexSet in
                        deleteFetchedProperties(at: indexSet, from: entity)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom toolbar
            HStack {
                Button(action: onAddFetchedProperty) {
                    Label("Add Fetched Property", systemImage: "plus")
                }
                
                Spacer()
                
                Button(action: {
                    if let entity = entity, let fetchedPropertyId = selectedFetchedPropertyId {
                        if let fetchedProperty = entity.fetchedProperties.first(where: { $0.id == fetchedPropertyId }) {
                            document.removeFetchedProperty(fetchedProperty, from: entity)
                            selectedFetchedPropertyId = nil
                        }
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedFetchedPropertyId == nil)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteAttributes(at indexSet: IndexSet, from entity: CDEntity) {
        for index in indexSet {
            if index < entity.attributes.count {
                let attribute = entity.attributes[index]
                document.removeAttribute(attribute, from: entity)
                if attribute.id == selectedAttributeId {
                    selectedAttributeId = nil
                }
            }
        }
    }
    
    private func deleteRelationships(at indexSet: IndexSet, from entity: CDEntity) {
        for index in indexSet {
            if index < entity.relationships.count {
                let relationship = entity.relationships[index]
                document.removeRelationship(relationship, from: entity)
                if relationship.id == selectedRelationshipId {
                    selectedRelationshipId = nil
                }
            }
        }
    }
    
    private func deleteFetchedProperties(at indexSet: IndexSet, from entity: CDEntity) {
        for index in indexSet {
            if index < entity.fetchedProperties.count {
                let fetchedProperty = entity.fetchedProperties[index]
                document.removeFetchedProperty(fetchedProperty, from: entity)
                if fetchedProperty.id == selectedFetchedPropertyId {
                    selectedFetchedPropertyId = nil
                }
            }
        }
    }
}

// MARK: - Property Inspector View

struct PropertyInspectorView: View {
    @ObservedObject var document: CoreDataModelDocument
    @ObservedObject var selectionState: SelectionState
    
    private var entity: CDEntity? {
        guard let entityId = selectionState.selectedEntityId else { return nil }
        return document.model.entities.first { $0.id == entityId }
    }
    
    private var attribute: CDAttribute? {
        guard let entityId = selectionState.selectedEntityId,
              let attributeId = selectionState.selectedAttributeId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return nil
        }
        return entity.attributes.first { $0.id == attributeId }
    }
    
    private var relationship: CDRelationship? {
        guard let entityId = selectionState.selectedEntityId,
              let relationshipId = selectionState.selectedRelationshipId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return nil
        }
        return entity.relationships.first { $0.id == relationshipId }
    }
    
    private var fetchedProperty: CDFetchedProperty? {
        guard let entityId = selectionState.selectedEntityId,
              let fetchedPropertyId = selectionState.selectedFetchedPropertyId,
              let entity = document.model.entities.first(where: { $0.id == entityId }) else {
            return nil
        }
        return entity.fetchedProperties.first { $0.id == fetchedPropertyId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("INSPECTOR")
                .font(.headline)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
            
            ScrollView {
                VStack(spacing: 16) {
                    if let entity = entity {
                        if selectionState.selectedAttributeId != nil {
                            attributeInspector
                        } else if selectionState.selectedRelationshipId != nil {
                            relationshipInspector
                        } else if selectionState.selectedFetchedPropertyId != nil {
                            fetchedPropertyInspector
                        } else {
                            entityInspector
                        }
                    } else {
                        // No selection
                        VStack {
                            Spacer()
                            Text("No item selected")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Entity Inspector
    
    private var entityInspector: some View {
        Group {
            if let entity = entity {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Entity Properties")
                        .font(.headline)
                    
                    // Name
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Entity Name", text: Binding(
                            get: { entity.name },
                            set: { newValue in
                                if !newValue.isEmpty {
                                    entity.name = newValue
                                    document.isModified = true
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Class Name
                    VStack(alignment: .leading) {
                        Text("Class")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Class Name", text: Binding(
                            get: { entity.className ?? "" },
                            set: { newValue in
                                entity.className = newValue.isEmpty ? nil : newValue
                                document.isModified = true
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Parent Entity
                    VStack(alignment: .leading) {
                        Text("Parent Entity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: Binding(
                            get: { entity.parentEntity },
                            set: { newValue in
                                entity.parentEntity = newValue
                                document.isModified = true
                            }
                        )) {
                            Text("None").tag(nil as String?)
                            
                            ForEach(document.model.entities.filter { $0.id != entity.id }, id: \.id) { parentEntity in
                                Text(parentEntity.name).tag(parentEntity.name as String?)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Abstract
                    Toggle("Abstract Entity", isOn: Binding(
                        get: { entity.isAbstract },
                        set: { newValue in
                            entity.isAbstract = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // User Info
                    VStack(alignment: .leading) {
                        Text("User Info")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(Array(entity.userInfo.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .frame(width: 100, alignment: .leading)
                                
                                TextField("Value", text: Binding(
                                    get: { entity.userInfo[key] ?? "" },
                                    set: { newValue in
                                        entity.userInfo[key] = newValue
                                        document.isModified = true
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Add new user info entry
                        Button("Add User Info Entry") {
                            let newKey = "key\(entity.userInfo.count + 1)"
                            entity.userInfo[newKey] = "value"
                            document.isModified = true
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("No entity selected")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Attribute Inspector
    
    private var attributeInspector: some View {
        Group {
            if let attribute = attribute {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Attribute Properties")
                        .font(.headline)
                    
                    // Name
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Attribute Name", text: Binding(
                            get: { attribute.name },
                            set: { newValue in
                                if !newValue.isEmpty {
                                    attribute.name = newValue
                                    document.isModified = true
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Type
                    VStack(alignment: .leading) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: Binding(
                            get: { attribute.attributeType },
                            set: { newValue in
                                attribute.attributeType = newValue
                                document.isModified = true
                            }
                        )) {
                            ForEach(CDAttributeType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Default Value
                    VStack(alignment: .leading) {
                        Text("Default Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Default Value", text: Binding(
                            get: { attribute.defaultValue ?? "" },
                            set: { newValue in
                                attribute.defaultValue = newValue.isEmpty ? nil : newValue
                                document.isModified = true
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Optional
                    Toggle("Optional", isOn: Binding(
                        get: { attribute.isOptional },
                        set: { newValue in
                            attribute.isOptional = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // Transient
                    Toggle("Transient", isOn: Binding(
                        get: { attribute.isTransient },
                        set: { newValue in
                            attribute.isTransient = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // Indexed
                    Toggle("Indexed", isOn: Binding(
                        get: { attribute.isIndexed },
                        set: { newValue in
                            attribute.isIndexed = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // User Info
                    VStack(alignment: .leading) {
                        Text("User Info")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(Array(attribute.userInfo.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .frame(width: 100, alignment: .leading)
                                
                                TextField("Value", text: Binding(
                                    get: { attribute.userInfo[key] ?? "" },
                                    set: { newValue in
                                        attribute.userInfo[key] = newValue
                                        document.isModified = true
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Add new user info entry
                        Button("Add User Info Entry") {
                            let newKey = "key\(attribute.userInfo.count + 1)"
                            attribute.userInfo[newKey] = "value"
                            document.isModified = true
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("No attribute selected")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Relationship Inspector
    
    private var relationshipInspector: some View {
        Group {
            if let relationship = relationship {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Relationship Properties")
                        .font(.headline)
                    
                    // Name
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Relationship Name", text: Binding(
                            get: { relationship.name },
                            set: { newValue in
                                if !newValue.isEmpty {
                                    relationship.name = newValue
                                    document.isModified = true
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Destination Entity
                    VStack(alignment: .leading) {
                        Text("Destination")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: Binding(
                            get: { relationship.destinationEntity },
                            set: { newValue in
                                relationship.destinationEntity = newValue
                                document.isModified = true
                            }
                        )) {
                            ForEach(document.model.entities, id: \.id) { entity in
                                Text(entity.name).tag(entity.name)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Inverse Relationship
                    VStack(alignment: .leading) {
                        Text("Inverse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Get potential inverse relationships from the destination entity
                        let destinationEntity = document.model.entities.first { $0.name == relationship.destinationEntity }
                        let potentialInverses = destinationEntity?.relationships.filter { $0.destinationEntity == entity?.name } ?? []
                        
                        Picker("", selection: Binding(
                            get: { relationship.inverseRelationship },
                            set: { newValue in
                                relationship.inverseRelationship = newValue
                                document.isModified = true
                            }
                        )) {
                            Text("None").tag(nil as String?)
                            
                            ForEach(potentialInverses, id: \.id) { inverse in
                                Text(inverse.name).tag(inverse.name as String?)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Delete Rule
                    VStack(alignment: .leading) {
                        Text("Delete Rule")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: Binding(
                            get: { relationship.deleteRule },
                            set: { newValue in
                                relationship.deleteRule = newValue
                                document.isModified = true
                            }
                        )) {
                            ForEach(CDDeleteRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // To-Many
                    Toggle("To-Many", isOn: Binding(
                        get: { relationship.isToMany },
                        set: { newValue in
                            relationship.isToMany = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // Optional
                    Toggle("Optional", isOn: Binding(
                        get: { relationship.isOptional },
                        set: { newValue in
                            relationship.isOptional = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // Ordered (only relevant for to-many)
                    if relationship.isToMany {
                        Toggle("Ordered", isOn: Binding(
                            get: { relationship.isOrdered },
                            set: { newValue in
                                relationship.isOrdered = newValue
                                document.isModified = true
                            }
                        ))
                    }
                    
                    // Transient
                    Toggle("Transient", isOn: Binding(
                        get: { relationship.isTransient },
                        set: { newValue in
                            relationship.isTransient = newValue
                            document.isModified = true
                        }
                    ))
                    
                    // User Info
                    VStack(alignment: .leading) {
                        Text("User Info")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(Array(relationship.userInfo.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .frame(width: 100, alignment: .leading)
                                
                                TextField("Value", text: Binding(
                                    get: { relationship.userInfo[key] ?? "" },
                                    set: { newValue in
                                        relationship.userInfo[key] = newValue
                                        document.isModified = true
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Add new user info entry
                        Button("Add User Info Entry") {
                            let newKey = "key\(relationship.userInfo.count + 1)"
                            relationship.userInfo[newKey] = "value"
                            document.isModified = true
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("No relationship selected")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Fetched Property Inspector
    
    private var fetchedPropertyInspector: some View {
        Group {
            if let fetchedProperty = fetchedProperty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fetched Property")
                        .font(.headline)
                    
                    // Name
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Fetched Property Name", text: Binding(
                            get: { fetchedProperty.name },
                            set: { newValue in
                                if !newValue.isEmpty {
                                    fetchedProperty.name = newValue
                                    document.isModified = true
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Predicate
                    VStack(alignment: .leading) {
                        Text("Predicate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: Binding(
                            get: { fetchedProperty.predicate },
                            set: { newValue in
                                fetchedProperty.predicate = newValue
                                document.isModified = true
                            }
                        ))
                        .frame(height: 100)
                        .border(Color.secondary.opacity(0.3))
                    }
                    
                    // Fetch Limit
                    VStack(alignment: .leading) {
                        Text("Fetch Limit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Fetch Limit", value: Binding(
                            get: { fetchedProperty.fetchLimit ?? 0 },
                            set: { newValue in
                                fetchedProperty.fetchLimit = newValue > 0 ? newValue : nil
                                document.isModified = true
                            }
                        ), formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // User Info
                    VStack(alignment: .leading) {
                        Text("User Info")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(Array(fetchedProperty.userInfo.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .frame(width: 100, alignment: .leading)
                                
                                TextField("Value", text: Binding(
                                    get: { fetchedProperty.userInfo[key] ?? "" },
                                    set: { newValue in
                                        fetchedProperty.userInfo[key] = newValue
                                        document.isModified = true
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Add new user info entry
                        Button("Add User Info Entry") {
                            let newKey = "key\(fetchedProperty.userInfo.count + 1)"
                            fetchedProperty.userInfo[newKey] = "value"
                            document.isModified = true
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("No fetched property selected")
                    .foregroundColor(.secondary)
            }
        }
    }
}
