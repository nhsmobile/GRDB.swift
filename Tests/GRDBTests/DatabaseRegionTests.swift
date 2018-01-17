import XCTest
#if GRDBCIPHER
    @testable import GRDBCipher
#elseif GRDBCUSTOMSQLITE
    @testable import GRDBCustomSQLite
#else
    #if SWIFT_PACKAGE
        import CSQLite
    #else
        import SQLite3
    #endif
    @testable import GRDB
#endif

class DatabaseRegionTests : GRDBTestCase {
    
    func testRegionEquatable() {
        // An array of distinct selection infos
        let regions = [
            DatabaseRegion.fullDatabase,
            DatabaseRegion(),
            DatabaseRegion(table: "foo"),
            DatabaseRegion(table: "FOO"), // selection info is case-sensitive on table name
            DatabaseRegion(table: "foo", columns: ["a", "b"]),
            DatabaseRegion(table: "foo", columns: ["A", "B"]), // selection info is case-sensitive on columns names
            DatabaseRegion(table: "foo", columns: ["b", "c"]),
            DatabaseRegion(table: "foo", rowIds: [1, 2]),
            DatabaseRegion(table: "foo", rowIds: [2, 3]),
            DatabaseRegion(table: "bar")]
        
        for (i1, s1) in regions.enumerated() {
            for (i2, s2) in regions.enumerated() {
                if i1 == i2 {
                    XCTAssertEqual(s1, s2)
                } else {
                    XCTAssertNotEqual(s1, s2)
                }
            }
        }
    }
    
    func testRegionUnion() {
        let regions = [
            DatabaseRegion.fullDatabase,
            DatabaseRegion(),
            DatabaseRegion(table: "foo"),
            DatabaseRegion(table: "foo", columns: ["a", "b"]),
            DatabaseRegion(table: "foo", columns: ["b", "c"]),
            DatabaseRegion(table: "foo", rowIds: [1, 2]),
            DatabaseRegion(table: "foo", rowIds: [2, 3]),
            DatabaseRegion(table: "bar")]
        
        var unions: [DatabaseRegion] = []
        for s1 in regions {
            for s2 in regions {
                unions.append(s1.union(s2))
            }
        }
        
        XCTAssertEqual(unions.map { $0.description }, [
            "full database",
            "full database",
            "full database",
            "full database",
            "full database",
            "full database",
            "full database",
            "full database",
            
            "full database",
            "empty",
            "foo(*)",
            "foo(a,b)",
            "foo(b,c)",
            "foo(*)[1,2]",
            "foo(*)[2,3]",
            "bar(*)",
            
            "full database",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "bar(*),foo(*)",
            
            "full database",
            "foo(a,b)",
            "foo(*)",
            "foo(a,b)",
            "foo(a,b,c)",
            "foo(*)",
            "foo(*)",
            "bar(*),foo(a,b)",
            
            "full database",
            "foo(b,c)",
            "foo(*)",
            "foo(a,b,c)",
            "foo(b,c)",
            "foo(*)",
            "foo(*)",
            "bar(*),foo(b,c)",
            
            "full database",
            "foo(*)[1,2]",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "foo(*)[1,2]",
            "foo(*)[1,2,3]",
            "bar(*),foo(*)[1,2]",
            
            "full database",
            "foo(*)[2,3]",
            "foo(*)",
            "foo(*)",
            "foo(*)",
            "foo(*)[1,2,3]",
            "foo(*)[2,3]",
            "bar(*),foo(*)[2,3]",
            
            "full database",
            "bar(*)",
            "bar(*),foo(*)",
            "bar(*),foo(a,b)",
            "bar(*),foo(b,c)",
            "bar(*),foo(*)[1,2]",
            "bar(*),foo(*)[2,3]",
            "bar(*)"])
    }
    
    func testRegionUnionOfColumnsAndRows() {
        let regions = [
            DatabaseRegion(table: "foo", columns: ["a"]).intersection(DatabaseRegion(table: "foo", rowIds: [1])),
            DatabaseRegion(table: "foo", columns: ["b"]).intersection(DatabaseRegion(table: "foo", rowIds: [2])),
            ]
        
        var unions: [DatabaseRegion] = []
        for s1 in regions {
            for s2 in regions {
                unions.append(s1.union(s2))
            }
        }
        
        XCTAssertEqual(unions.map { $0.description }, ["foo(a)[1]", "foo(a,b)[1,2]", "foo(a,b)[1,2]", "foo(b)[2]"])
    }
    
    func testRegionIntersection() {
        let regions = [
            DatabaseRegion.fullDatabase,
            DatabaseRegion(),
            DatabaseRegion(table: "foo"),
            DatabaseRegion(table: "foo", columns: ["a", "b"]),
            DatabaseRegion(table: "foo", columns: ["b", "c"]),
            DatabaseRegion(table: "foo", rowIds: [1, 2]),
            DatabaseRegion(table: "foo", rowIds: [2, 3]),
            DatabaseRegion(table: "bar")]
        
        var intersection: [DatabaseRegion] = []
        for s1 in regions {
            for s2 in regions {
                intersection.append(s1.intersection(s2))
            }
        }
        
        XCTAssertEqual(intersection.map { $0.description }, [
            "full database",
            "empty",
            "foo(*)",
            "foo(a,b)",
            "foo(b,c)",
            "foo(*)[1,2]",
            "foo(*)[2,3]",
            "bar(*)",
            
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            
            "foo(*)",
            "empty",
            "foo(*)",
            "foo(a,b)",
            "foo(b,c)",
            "foo(*)[1,2]",
            "foo(*)[2,3]",
            "empty",
            
            "foo(a,b)",
            "empty",
            "foo(a,b)",
            "foo(a,b)",
            "foo(b)",
            "foo(a,b)[1,2]",
            "foo(a,b)[2,3]",
            "empty",
            
            "foo(b,c)",
            "empty",
            "foo(b,c)",
            "foo(b)",
            "foo(b,c)",
            "foo(b,c)[1,2]",
            "foo(b,c)[2,3]",
            "empty",
            
            "foo(*)[1,2]",
            "empty",
            "foo(*)[1,2]",
            "foo(a,b)[1,2]",
            "foo(b,c)[1,2]",
            "foo(*)[1,2]",
            "foo(*)[2]",
            "empty",
            
            "foo(*)[2,3]",
            "empty",
            "foo(*)[2,3]",
            "foo(a,b)[2,3]",
            "foo(b,c)[2,3]",
            "foo(*)[2]",
            "foo(*)[2,3]",
            "empty",
            
            "bar(*)",
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            "empty",
            "bar(*)"])
    }
    
    func testRegionIntersectionOfColumnsAndRows() {
        let regions = [
            DatabaseRegion(table: "foo", columns: ["a"]).intersection(DatabaseRegion(table: "foo", rowIds: [1])),
            DatabaseRegion(table: "foo", columns: ["b"]).intersection(DatabaseRegion(table: "foo", rowIds: [2])),
            ]
        
        var intersection: [DatabaseRegion] = []
        for s1 in regions {
            for s2 in regions {
                intersection.append(s1.intersection(s2))
            }
        }
        
        XCTAssertEqual(intersection.map { $0.description }, ["foo(a)[1]", "empty", "empty", "foo(b)[2]"])
    }

    func testSelectStatement() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER, name TEXT)")
            try db.execute("CREATE TABLE bar (id INTEGER, fooId INTEGER)")
            
            do {
                let statement = try db.makeSelectStatement("SELECT foo.name FROM FOO JOIN BAR ON fooId = foo.id")
                let expectedRegion = DatabaseRegion(table: "foo", columns: ["name", "id"])
                    .union(DatabaseRegion(table: "bar", columns: ["fooId"]))
                XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                XCTAssertEqual(statement.fetchedRegion.description, "bar(fooId),foo(id,name)")
            }
            do {
                let statement = try db.makeSelectStatement("SELECT COUNT(*) FROM foo")
                if sqlite3_libversion_number() < 3019000 {
                    let expectedRegion = DatabaseRegion.fullDatabase
                    XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                    XCTAssertEqual(statement.fetchedRegion.description, "full database")
                } else {
                    let expectedRegion = DatabaseRegion(table: "foo")
                    XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                    XCTAssertEqual(statement.fetchedRegion.description, "foo(*)")
                }
            }
        }
    }
    
    func testRegionRowIds() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER PRIMARY KEY, a TEXT)")
            struct Record: TableMapping {
                static let databaseTableName = "foo"
            }
            
            // Undefined rowIds
            
            do {
                let request = Record.all()
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)")
            }
            do {
                let request = Record.filter(Column("a") == 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)")
            }
            do {
                let request = Record.filter(Column("id") >= 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)")
            }
            
            do {
                let request = Record.filter((Column("id") == 1) || (Column("a") == "foo"))
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)")
            }

            // No rowId
            
            do {
                let request = Record.filter(Column("id") == nil)
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }

            do {
                let request = Record.filter(Column("id") === nil)
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }
            
            do {
                let request = Record.filter(nil == Column("id"))
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }
            
            do {
                let request = Record.filter(nil === Column("id"))
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }
            
            do {
                let request = Record.filter((Column("id") == 1) && (Column("id") == 2))
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }
            do {
                let request = Record.filter(key: 1).filter(key: 2)
                try XCTAssertEqual(request.fetchedRegion(db).description, "empty")
            }

            // Single rowId
            
            do {
                let request = Record.filter(Column("id") == 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(Column("id") === 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(Column("id") == 1 && Column("a") == "foo")
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(Column.rowID == 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(1 == Column("id"))
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(1 === Column("id"))
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(1 === Column.rowID)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(key: 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(key: 1).filter(key: 1)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }
            do {
                let request = Record.filter(key: 1).filter(Column("a") == "foo")
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1]")
            }

            // Multiple rowIds
            
            do {
                let request = Record.filter(Column("id") == 1 || Column.rowID == 2)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2]")
            }
            do {
                let request = Record.filter((Column("id") == 1 && Column("a") == "foo") || Column.rowID == 2)
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2]")
            }
            do {
                let request = Record.filter([1, 2, 3].contains(Column("id")))
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let request = Record.filter([1, 2, 3].contains(Column.rowID))
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let request = Record.filter(keys: [1, 2, 3])
                try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
        }
    }
    
    func testDatabaseRegionOfDerivedRequests() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER PRIMARY KEY, a TEXT)")
            struct Record: TableMapping {
                static let databaseTableName = "foo"
            }
            
            let request = Record.filter(keys: [1, 2, 3])
            try XCTAssertEqual(request.fetchedRegion(db).description, "foo(a,id)[1,2,3]")

            do {
                let derivedRequest: AnyRequest = AnyRequest(request)
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let derivedRequest: AnyTypedRequest<Record> = AnyTypedRequest(request)
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let derivedRequest: AnyTypedRequest<Row> = request.asRequest(of: Row.self)
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let derivedRequest: AdaptedTypedRequest = request.adapted { db in SuffixRowAdapter(fromIndex: 1) }
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                let derivedRequest: AdaptedRequest = AnyRequest(request).adapted { db in SuffixRowAdapter(fromIndex: 1) }
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)[1,2,3]")
            }
            do {
                // SQL request loses region info
                let derivedRequest: SQLRequest = try request.asSQLRequest(db)
                try XCTAssertEqual(derivedRequest.fetchedRegion(db).description, "foo(a,id)")
            }
        }
    }
    
    func testUpdateStatement() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER, bar TEXT, baz TEXT, qux TEXT)")
            let statement = try db.makeUpdateStatement("UPDATE foo SET bar = 'bar', baz = 'baz' WHERE id = 1")
            XCTAssertFalse(statement.invalidatesDatabaseSchemaCache)
            XCTAssertEqual(statement.databaseEventKinds.count, 1)
            guard case .update(let tableName, let columnNames) = statement.databaseEventKinds[0] else {
                XCTFail()
                return
            }
            XCTAssertEqual(tableName, "foo")
            XCTAssertEqual(columnNames, Set(["bar", "baz"]))
        }
    }
    
    func testRowIdNameInSelectStatement() throws {
        // Here we test that sqlite authorizer gives the "ROWID" name to
        // the rowid column, regardless of its name in the request (rowid, oid, _rowid_)
        //
        // See also testRowIdNameInUpdateStatement
        
        guard sqlite3_libversion_number() < 3019003 else {
            // This test fails on SQLite 3.19.3 (iOS 11.2) and SQLite 3.21.0 (custom build),
            // but succeeds on SQLite 3.16.0 (iOS 10.3.1).
            // TODO: evaluate the consequences
            return
        }
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (name TEXT)")
            do {
                let statement = try db.makeSelectStatement("SELECT rowid FROM FOO")
                let expectedRegion = DatabaseRegion(table: "foo", columns: ["ROWID"])
                XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                XCTAssertEqual(statement.fetchedRegion.description, "foo(ROWID)")
            }
            do {
                let statement = try db.makeSelectStatement("SELECT _ROWID_ FROM FOO")
                let expectedRegion = DatabaseRegion(table: "foo", columns: ["ROWID"])
                XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                XCTAssertEqual(statement.fetchedRegion.description, "foo(ROWID)")
            }
            do {
                let statement = try db.makeSelectStatement("SELECT oID FROM FOO")
                let expectedRegion = DatabaseRegion(table: "foo", columns: ["ROWID"])
                XCTAssertEqual(statement.fetchedRegion, expectedRegion)
                XCTAssertEqual(statement.fetchedRegion.description, "foo(ROWID)")
            }
        }
    }

    func testRowIdNameInUpdateStatement() throws {
        // Here we test that sqlite authorizer gives the "ROWID" name to
        // the rowid column, regardless of its name in the request (rowid, oid, _rowid_)
        //
        // See also testRowIdNameInSelectStatement
        
        guard sqlite3_libversion_number() > 3007013 else {
            // This test fails on iOS 8.1 (SQLite 3.7.13)
            // TODO: evaluate the consequences
            return
        }
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (name TEXT)")
            do {
                let statement = try db.makeUpdateStatement("UPDATE foo SET rowid = 1")
                XCTAssertEqual(statement.databaseEventKinds.count, 1)
                guard case .update(let tableName, let columnNames) = statement.databaseEventKinds[0] else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(tableName, "foo")
                XCTAssertEqual(columnNames, ["ROWID"])
            }
            do {
                let statement = try db.makeUpdateStatement("UPDATE foo SET _ROWID_ = 1")
                XCTAssertEqual(statement.databaseEventKinds.count, 1)
                guard case .update(let tableName, let columnNames) = statement.databaseEventKinds[0] else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(tableName, "foo")
                XCTAssertEqual(columnNames, ["ROWID"])
            }
            do {
                let statement = try db.makeUpdateStatement("UPDATE foo SET oID = 1")
                XCTAssertEqual(statement.databaseEventKinds.count, 1)
                guard case .update(let tableName, let columnNames) = statement.databaseEventKinds[0] else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(tableName, "foo")
                XCTAssertEqual(columnNames, ["ROWID"])
            }
        }
    }

    func testInsertStatement() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER, bar TEXT, baz TEXT, qux TEXT)")
            let statement = try db.makeUpdateStatement("INSERT INTO foo (id, bar) VALUES (1, 'bar')")
            XCTAssertFalse(statement.invalidatesDatabaseSchemaCache)
            XCTAssertEqual(statement.databaseEventKinds.count, 1)
            guard case .insert(let tableName) = statement.databaseEventKinds[0] else {
                XCTFail()
                return
            }
            XCTAssertEqual(tableName, "foo")
        }
    }

    func testDeleteStatement() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute("CREATE TABLE foo (id INTEGER, bar TEXT, baz TEXT, qux TEXT)")
            let statement = try db.makeUpdateStatement("DELETE FROM foo")
            XCTAssertFalse(statement.invalidatesDatabaseSchemaCache)
            XCTAssertEqual(statement.databaseEventKinds.count, 1)
            guard case .delete(let tableName) = statement.databaseEventKinds[0] else {
                XCTFail()
                return
            }
            XCTAssertEqual(tableName, "foo")
        }
    }

    func testUpdateStatementInvalidatesDatabaseSchemaCache() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            do {
                let statement = try db.makeUpdateStatement("CREATE TABLE foo (id INTEGER)")
                XCTAssertFalse(statement.invalidatesDatabaseSchemaCache)
                try statement.execute()
            }
            do {
                let statement = try db.makeUpdateStatement("ALTER TABLE foo ADD COLUMN name TEXT")
                XCTAssertTrue(statement.invalidatesDatabaseSchemaCache)
            }
            do {
                let statement = try db.makeUpdateStatement("DROP TABLE foo")
                XCTAssertTrue(statement.invalidatesDatabaseSchemaCache)
            }
        }
    }
    
    func testRegionIsModifiedByDatabaseEvent() {
        do {
            // Empty selection
            let region = DatabaseRegion()
            XCTAssertEqual(region.description, "empty")
            
            do {
                let eventKind = DatabaseEventKind.insert(tableName: "foo")
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }

            do {
                let eventKind = DatabaseEventKind.delete(tableName: "foo")
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
            
            do {
                let eventKind = DatabaseEventKind.update(tableName: "foo", columnNames: ["a", "b"])
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
        }
        
        do {
            // Full database selection
            let region = DatabaseRegion.fullDatabase
            XCTAssertEqual(region.description, "full database")
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.insert(tableName: tableName)
                    let event = DatabaseEvent(kind: .insert, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event))
                }
            }
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.delete(tableName: tableName)
                    let event = DatabaseEvent(kind: .delete, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event))
                }
            }
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.update(tableName: tableName, columnNames: ["a", "b"])
                    let event = DatabaseEvent(kind: .update, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event))
                }
            }
        }
        
        do {
            // Complex selection
            let region = DatabaseRegion(table: "foo")
                .union(DatabaseRegion(table: "bar", columns: ["a"])
                    .intersection(DatabaseRegion(table: "bar", rowIds: [1])))
            XCTAssertEqual(region.description, "bar(a)[1],foo(*)")
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.insert(tableName: tableName)
                    let event1 = DatabaseEvent(kind: .insert, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .insert, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertTrue(region.isModified(by: event2))
                }
            }
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.delete(tableName: tableName)
                    let event1 = DatabaseEvent(kind: .delete, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .delete, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertTrue(region.isModified(by: event2))
                }
            }
            
            do {
                let tableName = "foo"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.update(tableName: tableName, columnNames: ["a", "b"])
                    let event1 = DatabaseEvent(kind: .update, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .update, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertTrue(region.isModified(by: event2))
                }
            }
            
            do {
                let tableName = "bar"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.insert(tableName: tableName)
                    let event1 = DatabaseEvent(kind: .insert, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .insert, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertFalse(region.isModified(by: event2))
                }
            }
            
            do {
                let tableName = "bar"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.delete(tableName: tableName)
                    let event1 = DatabaseEvent(kind: .delete, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .delete, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertFalse(region.isModified(by: event2))
                }
            }
            
            do {
                let tableName = "bar"
                tableName.withCString { tableNameCString in
                    let eventKind = DatabaseEventKind.update(tableName: tableName, columnNames: ["a", "b"])
                    let event1 = DatabaseEvent(kind: .update, rowID: 1, databaseNameCString: nil, tableNameCString: tableNameCString)
                    let event2 = DatabaseEvent(kind: .update, rowID: 2, databaseNameCString: nil, tableNameCString: tableNameCString)
                    XCTAssertTrue(region.isModified(byEventsOfKind: eventKind))
                    XCTAssertTrue(region.isModified(by: event1))
                    XCTAssertFalse(region.isModified(by: event2))
                }
            }
            
            do {
                let eventKind = DatabaseEventKind.update(tableName: "bar", columnNames: ["b", "c"])
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
            
            do {
                let eventKind = DatabaseEventKind.insert(tableName: "qux")
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
            
            do {
                let eventKind = DatabaseEventKind.delete(tableName: "qux")
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
            
            do {
                let eventKind = DatabaseEventKind.update(tableName: "qux", columnNames: ["a", "b"])
                XCTAssertFalse(region.isModified(byEventsOfKind: eventKind))
                // Can't test for individual events due to DatabaseRegion.isModified(by:) precondition
            }
        }
    }
}
