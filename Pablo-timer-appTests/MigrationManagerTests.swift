import XCTest
@testable import Pablo_timer_app

final class MigrationManagerTests: XCTestCase {
    var migrationManager: MigrationManager!
    let testSchemaVersionKey = "com.pablo.timer-app.schemaVersion"
    
    override func setUp() {
        super.setUp()
        // Use the shared instance for testing
        migrationManager = MigrationManager.shared
        
        // Clear any existing schema version
        UserDefaults.standard.removeObject(forKey: testSchemaVersionKey)
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: testSchemaVersionKey)
        super.tearDown()
    }
    
    func testInitialSchemaVersion() {
        // When the app is first installed, storedSchemaVersion should be 0
        XCTAssertEqual(migrationManager.storedSchemaVersion, 0)
    }
    
    func testCheckAndPerformMigrationForFirstInstall() {
        // Given - First install (no stored version)
        XCTAssertEqual(migrationManager.storedSchemaVersion, 0)
        
        // When
        migrationManager.checkAndPerformMigration()
        
        // Then - Should update to current version without performing migrations
        XCTAssertEqual(migrationManager.storedSchemaVersion, migrationManager.currentSchemaVersion)
    }
    
    func testCheckAndPerformMigrationForSameVersion() {
        // Given - Already on current version
        UserDefaults.standard.set(migrationManager.currentSchemaVersion, forKey: testSchemaVersionKey)
        
        // When
        migrationManager.checkAndPerformMigration()
        
        // Then - Should remain at current version
        XCTAssertEqual(migrationManager.storedSchemaVersion, migrationManager.currentSchemaVersion)
    }
    
    func testCheckAndPerformMigrationForOlderVersion() {
        // Given - Older version
        let olderVersion = migrationManager.currentSchemaVersion - 1
        UserDefaults.standard.set(olderVersion, forKey: testSchemaVersionKey)
        
        // When
        migrationManager.checkAndPerformMigration()
        
        // Then - Should update to current version
        XCTAssertEqual(migrationManager.storedSchemaVersion, migrationManager.currentSchemaVersion)
    }
    
    func testCheckAndPerformMigrationForNewerVersion() {
        // Given - Newer version (should not happen in practice)
        let newerVersion = migrationManager.currentSchemaVersion + 1
        UserDefaults.standard.set(newerVersion, forKey: testSchemaVersionKey)
        
        // When
        migrationManager.checkAndPerformMigration()
        
        // Then - Should not change the version
        XCTAssertEqual(migrationManager.storedSchemaVersion, newerVersion)
    }
    
    func testSequentialMigrations() {
        // This test verifies that migrations are performed sequentially
        // For example, if stored version is 1 and current is 3, it should
        // perform migrations 1→2 and then 2→3
        
        // Given - We're using a spy to track migration calls
        let migrationSpy = MigrationManagerSpy()
        
        // Set stored version to 1 (assuming current is higher)
        UserDefaults.standard.set(1, forKey: testSchemaVersionKey)
        
        // When
        migrationSpy.checkAndPerformMigration()
        
        // Then
        // If current version is 1, no migrations should happen
        if migrationSpy.currentSchemaVersion == 1 {
            XCTAssertEqual(migrationSpy.migrateFromToCalls.count, 0)
        } 
        // If current version is 2, one migration should happen: 1→2
        else if migrationSpy.currentSchemaVersion == 2 {
            XCTAssertEqual(migrationSpy.migrateFromToCalls.count, 1)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[0].from, 1)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[0].to, 2)
        }
        // If current version is 3, two migrations should happen: 1→2 and 2→3
        else if migrationSpy.currentSchemaVersion == 3 {
            XCTAssertEqual(migrationSpy.migrateFromToCalls.count, 2)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[0].from, 1)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[0].to, 2)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[1].from, 2)
            XCTAssertEqual(migrationSpy.migrateFromToCalls[1].to, 3)
        }
    }
}

// MARK: - Test Helpers

/// A spy class that tracks migration calls
class MigrationManagerSpy: MigrationManager {
    struct MigrationCall {
        let from: Int
        let to: Int
    }
    
    var migrateFromToCalls: [MigrationCall] = []
    
    override func migrateFrom(version fromVersion: Int, to toVersion: Int) {
        migrateFromToCalls.append(MigrationCall(from: fromVersion, to: toVersion))
        super.migrateFrom(version: fromVersion, to: toVersion)
    }
} 