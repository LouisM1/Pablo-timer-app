import Foundation
import SwiftData

// MARK: - ModelContext Extensions

extension ModelContext {
    /// Performs a batch delete operation for all entities of a specific type
    /// - Parameter type: The type of entity to delete
    /// - Returns: The number of entities deleted
    @discardableResult
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        let items = try fetch(descriptor)
        var count = 0
        
        for item in items {
            delete(item)
            count += 1
        }
        
        try save()
        return count
    }
    
    /// Checks if an entity with the specified ID exists
    /// - Parameters:
    ///   - id: The ID to check for
    ///   - keyPath: The key path to the ID property
    /// - Returns: True if an entity with the ID exists, false otherwise
    func exists<T: PersistentModel, ID: Equatable>(_ type: T.Type, id: ID, keyPath: KeyPath<T, ID>) throws -> Bool {
        // Fetch all entities and then filter manually
        // This avoids the issue with keyPath in predicates
        let descriptor = FetchDescriptor<T>()
        let results = try fetch(descriptor)
        
        // Check if any entity has the matching ID
        return results.contains { entity in
            entity[keyPath: keyPath] == id
        }
    }
    
    /// Counts the number of entities of a specific type
    /// - Parameter type: The type of entity to count
    /// - Returns: The number of entities
    func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try fetchCount(descriptor)
    }
}

// MARK: - FetchDescriptor Extensions

extension FetchDescriptor {
    /// Creates a new FetchDescriptor with a specified fetch limit
    /// - Parameter limit: The maximum number of results to fetch
    /// - Returns: A new FetchDescriptor with the specified limit
    func limit(_ limit: Int) -> FetchDescriptor {
        var descriptor = self
        descriptor.fetchLimit = limit
        return descriptor
    }
    
    /// Creates a new FetchDescriptor with the specified offset
    /// - Parameter offset: The number of results to skip
    /// - Returns: A new FetchDescriptor with the specified offset
    func offset(_ offset: Int) -> FetchDescriptor {
        var descriptor = self
        descriptor.fetchOffset = offset
        return descriptor
    }
    
    /// Creates a new FetchDescriptor with the specified sort descriptors
    /// - Parameter sortBy: The sort descriptors to apply
    /// - Returns: A new FetchDescriptor with the specified sort descriptors
    func sorted(by sortBy: [SortDescriptor<T>]) -> FetchDescriptor {
        var descriptor = self
        descriptor.sortBy = sortBy
        return descriptor
    }
} 