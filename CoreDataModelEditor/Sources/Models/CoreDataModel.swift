import Foundation
import Combine
import XMLCoder

// MARK: - Attribute Type Enums
enum CDAttributeType: String, Codable, CaseIterable {
    case integer16 = "Integer 16"
    case integer32 = "Integer 32"
    case integer64 = "Integer 64"
    case decimal = "Decimal"
    case double = "Double"
    case float = "Float"
    case string = "String"
    case boolean = "Boolean"
    case date = "Date"
    case binaryData = "Binary Data"
    case uuid = "UUID"
    case uri = "URI"
    case transformable = "Transformable"
    case objectID = "Object ID"
    
    var xmlValue: String {
        switch self {
        case .integer16: return "Integer 16"
        case .integer32: return "Integer 32"
        case .integer64: return "Integer 64"
        case .decimal: return "Decimal"
        case .double: return "Double"
        case .float: return "Float"
        case .string: return "String"
        case .boolean: return "Boolean"
        case .date: return "Date"
        case .binaryData: return "Binary"
        case .uuid: return "UUID"
        case .uri: return "URI"
        case .transformable: return "Transformable"
        case .objectID: return "ObjectID"
        }
    }
}

enum CDDeleteRule: String, Codable, CaseIterable {
    case nullify = "Nullify"
    case cascade = "Cascade"
    case deny = "Deny"
    case noAction = "No Action"
}

// MARK: - Core Data Model
class CoreDataModel: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var entities: [CDEntity]
    @Published var configurations: [CDConfiguration]
    @Published var version: String
    @Published var currentVersion: Bool
    
    // XML file path for saving/loading
    var filePath: URL?
    
    enum CodingKeys: String, CodingKey {
        case name, entities, configurations, version, currentVersion
    }
    
    init(name: String = "Untitled", entities: [CDEntity] = [], configurations: [CDConfiguration] = [], version: String = "1.0", currentVersion: Bool = true) {
        self.name = name
        self.entities = entities
        self.configurations = configurations
        self.version = version
        self.currentVersion = currentVersion
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        entities = try container.decode([CDEntity].self, forKey: .entities)
        configurations = try container.decode([CDConfiguration].self, forKey: .configurations)
        version = try container.decode(String.self, forKey: .version)
        currentVersion = try container.decode(Bool.self, forKey: .currentVersion)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(entities, forKey: .entities)
        try container.encode(configurations, forKey: .configurations)
        try container.encode(version, forKey: .version)
        try container.encode(currentVersion, forKey: .currentVersion)
    }
    
    // MARK: - Helper Methods
    func addEntity(name: String) -> CDEntity {
        let entity = CDEntity(name: name)
        entities.append(entity)
        return entity
    }
    
    func removeEntity(_ entity: CDEntity) {
        entities.removeAll { $0.id == entity.id }
    }
    
    func addConfiguration(name: String) -> CDConfiguration {
        let configuration = CDConfiguration(name: name)
        configurations.append(configuration)
        return configuration
    }
    
    func removeConfiguration(_ configuration: CDConfiguration) {
        configurations.removeAll { $0.id == configuration.id }
    }
    
    func entityWithName(_ name: String) -> CDEntity? {
        return entities.first { $0.name == name }
    }
}

// MARK: - Entity
class CDEntity: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var className: String?
    @Published var parentEntity: String?
    @Published var isAbstract: Bool
    @Published var userInfo: [String: String]
    @Published var attributes: [CDAttribute]
    @Published var relationships: [CDRelationship]
    @Published var fetchedProperties: [CDFetchedProperty]
    @Published var uniquenessConstraints: [[String]]
    @Published var compoundIndexes: [[String]]
    
    enum CodingKeys: String, CodingKey {
        case id, name, className, parentEntity, isAbstract, userInfo, attributes, relationships, fetchedProperties, uniquenessConstraints, compoundIndexes
    }
    
    init(name: String, className: String? = nil, parentEntity: String? = nil, isAbstract: Bool = false, userInfo: [String: String] = [:], attributes: [CDAttribute] = [], relationships: [CDRelationship] = [], fetchedProperties: [CDFetchedProperty] = [], uniquenessConstraints: [[String]] = [], compoundIndexes: [[String]] = []) {
        self.name = name
        self.className = className
        self.parentEntity = parentEntity
        self.isAbstract = isAbstract
        self.userInfo = userInfo
        self.attributes = attributes
        self.relationships = relationships
        self.fetchedProperties = fetchedProperties
        self.uniquenessConstraints = uniquenessConstraints
        self.compoundIndexes = compoundIndexes
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        className = try container.decodeIfPresent(String.self, forKey: .className)
        parentEntity = try container.decodeIfPresent(String.self, forKey: .parentEntity)
        isAbstract = try container.decode(Bool.self, forKey: .isAbstract)
        userInfo = try container.decode([String: String].self, forKey: .userInfo)
        attributes = try container.decode([CDAttribute].self, forKey: .attributes)
        relationships = try container.decode([CDRelationship].self, forKey: .relationships)
        fetchedProperties = try container.decode([CDFetchedProperty].self, forKey: .fetchedProperties)
        uniquenessConstraints = try container.decode([[String]].self, forKey: .uniquenessConstraints)
        compoundIndexes = try container.decode([[String]].self, forKey: .compoundIndexes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(className, forKey: .className)
        try container.encodeIfPresent(parentEntity, forKey: .parentEntity)
        try container.encode(isAbstract, forKey: .isAbstract)
        try container.encode(userInfo, forKey: .userInfo)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(fetchedProperties, forKey: .fetchedProperties)
        try container.encode(uniquenessConstraints, forKey: .uniquenessConstraints)
        try container.encode(compoundIndexes, forKey: .compoundIndexes)
    }
    
    // MARK: - Helper Methods
    func addAttribute(name: String, type: CDAttributeType) -> CDAttribute {
        let attribute = CDAttribute(name: name, attributeType: type)
        attributes.append(attribute)
        return attribute
    }
    
    func removeAttribute(_ attribute: CDAttribute) {
        attributes.removeAll { $0.id == attribute.id }
    }
    
    func addRelationship(name: String, destinationEntity: String) -> CDRelationship {
        let relationship = CDRelationship(name: name, destinationEntity: destinationEntity)
        relationships.append(relationship)
        return relationship
    }
    
    func removeRelationship(_ relationship: CDRelationship) {
        relationships.removeAll { $0.id == relationship.id }
    }
    
    func addFetchedProperty(name: String, predicate: String) -> CDFetchedProperty {
        let fetchedProperty = CDFetchedProperty(name: name, predicate: predicate)
        fetchedProperties.append(fetchedProperty)
        return fetchedProperty
    }
    
    func removeFetchedProperty(_ fetchedProperty: CDFetchedProperty) {
        fetchedProperties.removeAll { $0.id == fetchedProperty.id }
    }
}

// MARK: - Attribute
class CDAttribute: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var attributeType: CDAttributeType
    @Published var defaultValue: String?
    @Published var isOptional: Bool
    @Published var isTransient: Bool
    @Published var isIndexed: Bool
    @Published var userInfo: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, attributeType, defaultValue, isOptional, isTransient, isIndexed, userInfo
    }
    
    init(name: String, attributeType: CDAttributeType = .string, defaultValue: String? = nil, isOptional: Bool = true, isTransient: Bool = false, isIndexed: Bool = false, userInfo: [String: String] = [:]) {
        self.name = name
        self.attributeType = attributeType
        self.defaultValue = defaultValue
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.isIndexed = isIndexed
        self.userInfo = userInfo
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        attributeType = try container.decode(CDAttributeType.self, forKey: .attributeType)
        defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
        isOptional = try container.decode(Bool.self, forKey: .isOptional)
        isTransient = try container.decode(Bool.self, forKey: .isTransient)
        isIndexed = try container.decode(Bool.self, forKey: .isIndexed)
        userInfo = try container.decode([String: String].self, forKey: .userInfo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(attributeType, forKey: .attributeType)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encode(isOptional, forKey: .isOptional)
        try container.encode(isTransient, forKey: .isTransient)
        try container.encode(isIndexed, forKey: .isIndexed)
        try container.encode(userInfo, forKey: .userInfo)
    }
}

// MARK: - Relationship
class CDRelationship: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var destinationEntity: String
    @Published var inverseRelationship: String?
    @Published var deleteRule: CDDeleteRule
    @Published var isOptional: Bool
    @Published var isTransient: Bool
    @Published var isToMany: Bool
    @Published var isOrdered: Bool
    @Published var minCount: Int?
    @Published var maxCount: Int?
    @Published var userInfo: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, destinationEntity, inverseRelationship, deleteRule, isOptional, isTransient, isToMany, isOrdered, minCount, maxCount, userInfo
    }
    
    init(name: String, destinationEntity: String, inverseRelationship: String? = nil, deleteRule: CDDeleteRule = .nullify, isOptional: Bool = true, isTransient: Bool = false, isToMany: Bool = false, isOrdered: Bool = false, minCount: Int? = nil, maxCount: Int? = nil, userInfo: [String: String] = [:]) {
        self.name = name
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
        self.deleteRule = deleteRule
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.isToMany = isToMany
        self.isOrdered = isOrdered
        self.minCount = minCount
        self.maxCount = maxCount
        self.userInfo = userInfo
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        destinationEntity = try container.decode(String.self, forKey: .destinationEntity)
        inverseRelationship = try container.decodeIfPresent(String.self, forKey: .inverseRelationship)
        deleteRule = try container.decode(CDDeleteRule.self, forKey: .deleteRule)
        isOptional = try container.decode(Bool.self, forKey: .isOptional)
        isTransient = try container.decode(Bool.self, forKey: .isTransient)
        isToMany = try container.decode(Bool.self, forKey: .isToMany)
        isOrdered = try container.decode(Bool.self, forKey: .isOrdered)
        minCount = try container.decodeIfPresent(Int.self, forKey: .minCount)
        maxCount = try container.decodeIfPresent(Int.self, forKey: .maxCount)
        userInfo = try container.decode([String: String].self, forKey: .userInfo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(destinationEntity, forKey: .destinationEntity)
        try container.encodeIfPresent(inverseRelationship, forKey: .inverseRelationship)
        try container.encode(deleteRule, forKey: .deleteRule)
        try container.encode(isOptional, forKey: .isOptional)
        try container.encode(isTransient, forKey: .isTransient)
        try container.encode(isToMany, forKey: .isToMany)
        try container.encode(isOrdered, forKey: .isOrdered)
        try container.encodeIfPresent(minCount, forKey: .minCount)
        try container.encodeIfPresent(maxCount, forKey: .maxCount)
        try container.encode(userInfo, forKey: .userInfo)
    }
}

// MARK: - Fetched Property
class CDFetchedProperty: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var predicate: String
    @Published var fetchLimit: Int?
    @Published var userInfo: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, predicate, fetchLimit, userInfo
    }
    
    init(name: String, predicate: String, fetchLimit: Int? = nil, userInfo: [String: String] = [:]) {
        self.name = name
        self.predicate = predicate
        self.fetchLimit = fetchLimit
        self.userInfo = userInfo
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        predicate = try container.decode(String.self, forKey: .predicate)
        fetchLimit = try container.decodeIfPresent(Int.self, forKey: .fetchLimit)
        userInfo = try container.decode([String: String].self, forKey: .userInfo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(predicate, forKey: .predicate)
        try container.encodeIfPresent(fetchLimit, forKey: .fetchLimit)
        try container.encode(userInfo, forKey: .userInfo)
    }
}

// MARK: - Configuration
class CDConfiguration: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var entityNames: [String]
    @Published var userInfo: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, entityNames, userInfo
    }
    
    init(name: String, entityNames: [String] = [], userInfo: [String: String] = [:]) {
        self.name = name
        self.entityNames = entityNames
        self.userInfo = userInfo
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        entityNames = try container.decode([String].self, forKey: .entityNames)
        userInfo = try container.decode([String: String].self, forKey: .userInfo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(entityNames, forKey: .entityNames)
        try container.encode(userInfo, forKey: .userInfo)
    }
    
    // MARK: - Helper Methods
    func addEntity(_ entityName: String) {
        if !entityNames.contains(entityName) {
            entityNames.append(entityName)
        }
    }
    
    func removeEntity(_ entityName: String) {
        entityNames.removeAll { $0 == entityName }
    }
}
