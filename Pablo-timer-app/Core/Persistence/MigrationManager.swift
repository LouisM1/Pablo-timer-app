import Foundation
import SwiftData
import OSLog

/// Manages schema migrations for SwiftData
final class MigrationManager {
    private let logger = Logger(subsystem: "com.pablo.timer-app", category: "Migration")
    
    /// The shared instance for app-wide use
    static let shared = MigrationManager()
    
    private init() {}
    
    /// The current schema version of the app
    /// Increment this value when making schema changes
    let currentSchemaVersion = 1
    
    /// The key used to store the schema version in UserDefaults
    private let schemaVersionKey = "com.pablo.timer-app.schemaVersion"
    
    /// Returns the stored schema version from UserDefaults
    var storedSchemaVersion: Int {
        UserDefaults.standard.integer(forKey: schemaVersionKey)
    }
    
    /// Updates the stored schema version in UserDefaults
    /// - Parameter version: The new schema version
    private func updateStoredSchemaVersion(to version: Int) {
        UserDefaults.standard.set(version, forKey: schemaVersionKey)
    }
    
    /// Checks if a migration is needed and performs it if necessary
    func checkAndPerformMigration() {
        let storedVersion = storedSchemaVersion
        
        // If this is a first install or we're on the current version, no migration needed
        if storedVersion == 0 || storedVersion == currentSchemaVersion {
            updateStoredSchemaVersion(to: currentSchemaVersion)
            logger.debug("No migration needed. Current schema version: \(currentSchemaVersion)")
            return
        }
        
        // If the stored version is higher than current, something is wrong
        if storedVersion > currentSchemaVersion {
            logger.error("Stored schema version (\(storedVersion)) is higher than current (\(currentSchemaVersion)). This should not happen.")
            return
        }
        
        // Perform migrations sequentially
        for version in storedVersion..<currentSchemaVersion {
            migrateFrom(version: version, to: version + 1)
        }
        
        // Update the stored version
        updateStoredSchemaVersion(to: currentSchemaVersion)
        logger.debug("Migration completed. Schema updated to version \(currentSchemaVersion)")
    }
    
    /// Performs a migration from one version to the next
    /// - Parameters:
    ///   - fromVersion: The version to migrate from
    ///   - toVersion: The version to migrate to
    internal func migrateFrom(version fromVersion: Int, to toVersion: Int) {
        logger.debug("Migrating from schema version \(fromVersion) to \(toVersion)")
        
        // Implement specific migrations based on version numbers
        switch (fromVersion, toVersion) {
        case (1, 2):
            // Example: migrateV1ToV2()
            break
            
        case (2, 3):
            // Example: migrateV2ToV3()
            break
            
        default:
            logger.error("No migration path defined from version \(fromVersion) to \(toVersion)")
        }
    }
    
    // MARK: - Specific Migration Methods
    
    /// Example migration from version 1 to version 2
    private func migrateV1ToV2() {
        // Implementation would depend on the specific changes
        // For example:
        // 1. Fetch all entities of a certain type
        // 2. Update their properties or relationships
        // 3. Save the changes
        
        logger.debug("Completed migration from v1 to v2")
    }
} 