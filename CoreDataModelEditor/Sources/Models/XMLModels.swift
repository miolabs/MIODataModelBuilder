import Foundation
import XMLCoder

// MARK: - XML Model Structures for Core Data Model (.xcdatamodeld) files

// Root model element
struct XMLModel: Codable, DynamicNodeEncoding {
    var entities: [XMLEntity]
    var configurations: [XMLConfiguration]?
    var elements: [XMLElement]?
    var fetchRequests: [XMLFetchRequest]?
    
    var type: String
    var name: String
    var userDefinedModelVersionIdentifier: String?
    var lastSavedToolsVersion: String?
    var documentVersion: String?
    var minimumToolsVersion: String?
    var systemVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case entities = "entity"
        case configurations = "configuration"
        case elements = "element"
        case fetchRequests = "fetchRequest"
        case type
        case name
        case userDefinedModelVersionIdentifier
        case lastSavedToolsVersion
        case documentVersion
        case minimumToolsVersion
        case systemVersion
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.entities, CodingKeys.configurations, CodingKeys.elements, CodingKeys.fetchRequests:
            return .element
        default:
            return .attribute
        }
    }
}

// Entity element
struct XMLEntity: Codable, DynamicNodeEncoding {
    var attributes: [XMLAttribute]?
    var relationships: [XMLRelationship]?
    var fetchedProperties: [XMLFetchedProperty]?
    var uniquenessConstraints: [XMLUniquenessConstraint]?
    var compoundIndexes: [XMLCompoundIndex]?
    var userInfo: XMLUserInfo?
    
    var name: String
    var representedClassName: String?
    var syncable: String?
    var codeGenerationType: String?
    var isAbstract: String?
    var parentEntity: String?
    
    enum CodingKeys: String, CodingKey {
        case attributes = "attribute"
        case relationships = "relationship"
        case fetchedProperties = "fetchedProperty"
        case uniquenessConstraints = "uniquenessConstraints"
        case compoundIndexes = "compoundIndexes"
        case userInfo
        case name
        case representedClassName
        case syncable
        case codeGenerationType
        case isAbstract
        case parentEntity
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.attributes, CodingKeys.relationships, CodingKeys.fetchedProperties,
             CodingKeys.uniquenessConstraints, CodingKeys.compoundIndexes, CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Attribute element
struct XMLAttribute: Codable, DynamicNodeEncoding {
    var userInfo: XMLUserInfo?
    
    var name: String
    var attributeType: String
    var defaultValueString: String?
    var optional: String?
    var indexed: String?
    var syncable: String?
    var transient: String?
    var minValueString: String?
    var maxValueString: String?
    var regularExpressionString: String?
    var customClassName: String?
    var usesScalarValueType: String?
    var versionHashModifier: String?
    
    enum CodingKeys: String, CodingKey {
        case userInfo
        case name
        case attributeType
        case defaultValueString
        case optional
        case indexed
        case syncable
        case transient
        case minValueString
        case maxValueString
        case regularExpressionString
        case customClassName
        case usesScalarValueType
        case versionHashModifier
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Relationship element
struct XMLRelationship: Codable, DynamicNodeEncoding {
    var userInfo: XMLUserInfo?
    var ordered: String?
    
    var name: String
    var destinationEntity: String
    var inverseEntity: String?
    var inverseName: String?
    var toMany: String?
    var optional: String?
    var deletionRule: String?
    var syncable: String?
    var maxCount: String?
    var minCount: String?
    var transient: String?
    var versionHashModifier: String?
    
    enum CodingKeys: String, CodingKey {
        case userInfo
        case ordered
        case name
        case destinationEntity
        case inverseEntity
        case inverseName
        case toMany
        case optional
        case deletionRule
        case syncable
        case maxCount
        case minCount
        case transient
        case versionHashModifier
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Fetched property element
struct XMLFetchedProperty: Codable, DynamicNodeEncoding {
    var userInfo: XMLUserInfo?
    
    var name: String
    var fetchRequest: String
    var optional: String?
    var syncable: String?
    
    enum CodingKeys: String, CodingKey {
        case userInfo
        case name
        case fetchRequest
        case optional
        case syncable
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Configuration element
struct XMLConfiguration: Codable, DynamicNodeEncoding {
    var memberEntity: [XMLMemberEntity]?
    var userInfo: XMLUserInfo?
    
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case memberEntity
        case userInfo
        case name
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.memberEntity, CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Member entity for configurations
struct XMLMemberEntity: Codable, DynamicNodeEncoding {
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .attribute
    }
}

// Uniqueness constraint
struct XMLUniquenessConstraint: Codable, DynamicNodeEncoding {
    var constraint: [XMLConstraint]?
    
    enum CodingKeys: String, CodingKey {
        case constraint
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .element
    }
}

// Constraint element
struct XMLConstraint: Codable, DynamicNodeEncoding {
    var value: String
    
    enum CodingKeys: String, CodingKey {
        case value
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .attribute
    }
}

// Compound index
struct XMLCompoundIndex: Codable, DynamicNodeEncoding {
    var index: [XMLIndex]?
    
    enum CodingKeys: String, CodingKey {
        case index
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .element
    }
}

// Index element
struct XMLIndex: Codable, DynamicNodeEncoding {
    var value: String
    
    enum CodingKeys: String, CodingKey {
        case value
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .attribute
    }
}

// User info
struct XMLUserInfo: Codable, DynamicNodeEncoding {
    var entries: [XMLUserInfoEntry]?
    
    enum CodingKeys: String, CodingKey {
        case entries = "entry"
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .element
    }
}

// User info entry
struct XMLUserInfoEntry: Codable, DynamicNodeEncoding {
    var key: String
    var value: String
    
    enum CodingKeys: String, CodingKey {
        case key
        case value
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        return .attribute
    }
}

// Element for model elements
struct XMLElement: Codable, DynamicNodeEncoding {
    var userInfo: XMLUserInfo?
    
    var name: String
    var positionX: String?
    var positionY: String?
    var width: String?
    var height: String?
    
    enum CodingKeys: String, CodingKey {
        case userInfo
        case name
        case positionX
        case positionY
        case width
        case height
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// Fetch request
struct XMLFetchRequest: Codable, DynamicNodeEncoding {
    var userInfo: XMLUserInfo?
    var predicateString: String?
    var fetchLimit: String?
    var fetchBatchSize: String?
    
    var name: String
    var entity: String
    
    enum CodingKeys: String, CodingKey {
        case userInfo
        case predicateString
        case fetchLimit
        case fetchBatchSize
        case name
        case entity
    }
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.userInfo:
            return .element
        default:
            return .attribute
        }
    }
}

// MARK: - Conversion Extensions

// Extension to convert between our internal model and XML model
extension CoreDataModel {
    // Convert from XML model to our internal model
    static func from(xmlModel: XMLModel) -> CoreDataModel {
        let model = CoreDataModel(name: xmlModel.name)
        
        // Convert entities
        
        model.entities = xmlModel.entities.map { CDEntity.from(xmlEntity: $0) }
        
        
        // Convert configurations
        if let xmlConfigurations = xmlModel.configurations {
            model.configurations = xmlConfigurations.map { CDConfiguration.from(xmlConfiguration: $0) }
        }
        
        return model
    }
    
    // Convert to XML model for saving
    func toXMLModel() -> XMLModel {
        // Convert entities
        let xmlEntities = entities.map { $0.toXMLEntity() }
        
        // Convert configurations
        let xmlConfigurations = configurations.map { $0.toXMLConfiguration() }
        
        return XMLModel(
            entities: xmlEntities,
            configurations: xmlConfigurations.isEmpty ? nil : xmlConfigurations,
            elements: nil,
            fetchRequests: nil,
            type: "com.apple.IDECoreDataModeler.DataModel",
            name: name,
            userDefinedModelVersionIdentifier: version,
            lastSavedToolsVersion: "14000",
            documentVersion: "1.0",
            minimumToolsVersion: "Automatic",
            systemVersion: "14.0"
        )
    }
}

extension CDEntity {
    // Convert from XML entity to our internal entity
    static func from(xmlEntity: XMLEntity) -> CDEntity {
        let entity = CDEntity(
            name: xmlEntity.name,
            className: xmlEntity.representedClassName,
            parentEntity: xmlEntity.parentEntity,
            isAbstract: xmlEntity.isAbstract == "YES"
        )
        
        // Convert attributes
        if let xmlAttributes = xmlEntity.attributes {
            entity.attributes = xmlAttributes.map { CDAttribute.from(xmlAttribute: $0) }
        }
        
        // Convert relationships
        if let xmlRelationships = xmlEntity.relationships {
            entity.relationships = xmlRelationships.map { CDRelationship.from(xmlRelationship: $0) }
        }
        
        // Convert fetched properties
        if let xmlFetchedProperties = xmlEntity.fetchedProperties {
            entity.fetchedProperties = xmlFetchedProperties.map { CDFetchedProperty.from(xmlFetchedProperty: $0) }
        }
        
        // Convert user info
        if let xmlUserInfo = xmlEntity.userInfo, let entries = xmlUserInfo.entries {
            var userInfo: [String: String] = [:]
            for entry in entries {
                userInfo[entry.key] = entry.value
            }
            entity.userInfo = userInfo
        }
        
        return entity
    }
    
    // Convert to XML entity for saving
    func toXMLEntity() -> XMLEntity {
        // Convert attributes
        let xmlAttributes = attributes.map { $0.toXMLAttribute() }
        
        // Convert relationships
        let xmlRelationships = relationships.map { $0.toXMLRelationship() }
        
        // Convert fetched properties
        let xmlFetchedProperties = fetchedProperties.map { $0.toXMLFetchedProperty() }
        
        // Convert user info
        var xmlUserInfo: XMLUserInfo? = nil
        if !userInfo.isEmpty {
            let entries = userInfo.map { XMLUserInfoEntry(key: $0.key, value: $0.value) }
            xmlUserInfo = XMLUserInfo(entries: entries)
        }
        
        return XMLEntity(
            attributes: xmlAttributes.isEmpty ? nil : xmlAttributes,
            relationships: xmlRelationships.isEmpty ? nil : xmlRelationships,
            fetchedProperties: xmlFetchedProperties.isEmpty ? nil : xmlFetchedProperties,
            uniquenessConstraints: nil, // TODO: Implement
            compoundIndexes: nil, // TODO: Implement
            userInfo: xmlUserInfo,
            name: name,
            representedClassName: className,
            syncable: "YES",
            codeGenerationType: nil,
            isAbstract: isAbstract ? "YES" : "NO",
            parentEntity: parentEntity
        )
    }
}

extension CDAttribute {
    // Convert from XML attribute to our internal attribute
    static func from(xmlAttribute: XMLAttribute) -> CDAttribute {
        let attributeType = CDAttributeType.allCases.first { $0.xmlValue == xmlAttribute.attributeType } ?? .string
        
        let attribute = CDAttribute(
            name: xmlAttribute.name,
            attributeType: attributeType,
            defaultValue: xmlAttribute.defaultValueString,
            isOptional: xmlAttribute.optional == "YES",
            isTransient: xmlAttribute.transient == "YES",
            isIndexed: xmlAttribute.indexed == "YES"
        )
        
        // Convert user info
        if let xmlUserInfo = xmlAttribute.userInfo, let entries = xmlUserInfo.entries {
            var userInfo: [String: String] = [:]
            for entry in entries {
                userInfo[entry.key] = entry.value
            }
            attribute.userInfo = userInfo
        }
        
        return attribute
    }
    
    // Convert to XML attribute for saving
    func toXMLAttribute() -> XMLAttribute {
        // Convert user info
        var xmlUserInfo: XMLUserInfo? = nil
        if !userInfo.isEmpty {
            let entries = userInfo.map { XMLUserInfoEntry(key: $0.key, value: $0.value) }
            xmlUserInfo = XMLUserInfo(entries: entries)
        }
        
        return XMLAttribute(
            userInfo: xmlUserInfo,
            name: name,
            attributeType: attributeType.xmlValue,
            defaultValueString: defaultValue,
            optional: isOptional ? "YES" : "NO",
            indexed: isIndexed ? "YES" : "NO",
            syncable: "YES",
            transient: isTransient ? "YES" : "NO"
        )
    }
}

extension CDRelationship {
    // Convert from XML relationship to our internal relationship
    static func from(xmlRelationship: XMLRelationship) -> CDRelationship {
        let deleteRule = CDDeleteRule.allCases.first { 
            $0.rawValue == xmlRelationship.deletionRule 
        } ?? .nullify
        
        let relationship = CDRelationship(
            name: xmlRelationship.name,
            destinationEntity: xmlRelationship.destinationEntity,
            inverseRelationship: xmlRelationship.inverseName,
            deleteRule: deleteRule,
            isOptional: xmlRelationship.optional == "YES",
            isTransient: xmlRelationship.transient == "YES",
            isToMany: xmlRelationship.toMany == "YES",
            isOrdered: xmlRelationship.ordered == "YES",
            minCount: xmlRelationship.minCount != nil ? Int(xmlRelationship.minCount!) : nil,
            maxCount: xmlRelationship.maxCount != nil ? Int(xmlRelationship.maxCount!) : nil
        )
        
        // Convert user info
        if let xmlUserInfo = xmlRelationship.userInfo, let entries = xmlUserInfo.entries {
            var userInfo: [String: String] = [:]
            for entry in entries {
                userInfo[entry.key] = entry.value
            }
            relationship.userInfo = userInfo
        }
        
        return relationship
    }
    
    // Convert to XML relationship for saving
    func toXMLRelationship() -> XMLRelationship {
        // Convert user info
        var xmlUserInfo: XMLUserInfo? = nil
        if !userInfo.isEmpty {
            let entries = userInfo.map { XMLUserInfoEntry(key: $0.key, value: $0.value) }
            xmlUserInfo = XMLUserInfo(entries: entries)
        }
        
        return XMLRelationship(
            userInfo: xmlUserInfo,
            ordered: isOrdered ? "YES" : "NO",
            name: name,
            destinationEntity: destinationEntity,
            inverseEntity: nil, // Not typically used in modern Core Data
            inverseName: inverseRelationship,
            toMany: isToMany ? "YES" : "NO",
            optional: isOptional ? "YES" : "NO",
            deletionRule: deleteRule.rawValue,
            syncable: "YES",
            maxCount: maxCount != nil ? String(maxCount!) : nil,
            minCount: minCount != nil ? String(minCount!) : nil,
            transient: isTransient ? "YES" : "NO"
        )
    }
}

extension CDFetchedProperty {
    // Convert from XML fetched property to our internal fetched property
    static func from(xmlFetchedProperty: XMLFetchedProperty) -> CDFetchedProperty {
        let fetchedProperty = CDFetchedProperty(
            name: xmlFetchedProperty.name,
            predicate: xmlFetchedProperty.fetchRequest
        )
        
        // Convert user info
        if let xmlUserInfo = xmlFetchedProperty.userInfo, let entries = xmlUserInfo.entries {
            var userInfo: [String: String] = [:]
            for entry in entries {
                userInfo[entry.key] = entry.value
            }
            fetchedProperty.userInfo = userInfo
        }
        
        return fetchedProperty
    }
    
    // Convert to XML fetched property for saving
    func toXMLFetchedProperty() -> XMLFetchedProperty {
        // Convert user info
        var xmlUserInfo: XMLUserInfo? = nil
        if !userInfo.isEmpty {
            let entries = userInfo.map { XMLUserInfoEntry(key: $0.key, value: $0.value) }
            xmlUserInfo = XMLUserInfo(entries: entries)
        }
        
        return XMLFetchedProperty(
            userInfo: xmlUserInfo,
            name: name,
            fetchRequest: predicate,
            optional: "YES",
            syncable: "YES"
        )
    }
}

extension CDConfiguration {
    // Convert from XML configuration to our internal configuration
    static func from(xmlConfiguration: XMLConfiguration) -> CDConfiguration {
        let configuration = CDConfiguration(
            name: xmlConfiguration.name
        )
        
        // Convert member entities
        if let xmlMemberEntities = xmlConfiguration.memberEntity {
            configuration.entityNames = xmlMemberEntities.map { $0.name }
        }
        
        // Convert user info
        if let xmlUserInfo = xmlConfiguration.userInfo, let entries = xmlUserInfo.entries {
            var userInfo: [String: String] = [:]
            for entry in entries {
                userInfo[entry.key] = entry.value
            }
            configuration.userInfo = userInfo
        }
        
        return configuration
    }
    
    // Convert to XML configuration for saving
    func toXMLConfiguration() -> XMLConfiguration {
        // Convert member entities
        let xmlMemberEntities = entityNames.map { XMLMemberEntity(name: $0) }
        
        // Convert user info
        var xmlUserInfo: XMLUserInfo? = nil
        if !userInfo.isEmpty {
            let entries = userInfo.map { XMLUserInfoEntry(key: $0.key, value: $0.value) }
            xmlUserInfo = XMLUserInfo(entries: entries)
        }
        
        return XMLConfiguration(
            memberEntity: xmlMemberEntities.isEmpty ? nil : xmlMemberEntities,
            userInfo: xmlUserInfo,
            name: name
        )
    }
}
