//
//  MPDBManager+swift.swift
//  SBJSON_test
//
//  Created by pawelc on 14/07/2018.
//  Copyright © 2018 MP. All rights reserved.
//

import Foundation
import MPDBManager

@objc public extension MPDBManager  {

	public struct EntityKeys  {
		/// Key for entity Id
		public static var id = "Id"
		
		/// Key for entity deletion flag
		public static var deleted = "Deleted"
	}

	
	/// Type describes entity
	public typealias EntityDictionary = [String:Any]
	

	/// Error of entity validation
	///
	/// - missinngId: Entity is missing `Id` key
	public enum EntityError : Error {
		case missingId(entityName:String,entityDictionary:EntityDictionary)
	}
	
	public enum RuntimeError : Error {
		case `deinit`
	}
	
	@nonobjc open class func generateSQLParamList<T:Collection>(_ collection : T ) -> String {
		let sqlParameters = collection.map { _ in "?" }.joined(separator: ",")
		return sqlParameters
	}

	/// Update or insert entity into database
	///
	/// - Parameters:
	///   - name: Entity name (as in a database)
	///   - entityDictionary: Entity description
	///   - idKey: Name of the entity `Id` key, defaults to `MPDBManager.entityIdKey`
	///   - deletedKey: Name of the entity `Deleted` key, defaults to `MPDBManager.entityDeletedKey`
	/// - Throws: `EntityError` if entity not validates, database error in other case
	open func updateEntity(name : String, entityDictionary: EntityDictionary, idKey: String = EntityKeys.id, deletedKey: String = EntityKeys.deleted ) throws {
		
		// check if an Entity has an "Id" field
		guard let entityId = entityDictionary[idKey] else {
			throw EntityError.missingId(entityName: name, entityDictionary: entityDictionary)
		}
		
		// check for deletion
		if let deleted = entityDictionary[deletedKey] as? Bool, deleted==true {
			// delete
			let sql = "DELETE FROM \(name) WHERE \(idKey)=?"
			
			// execute SQL
			guard self.db.executeUpdate(sql, withArgumentsIn: [entityId]) else {
				throw self.db.lastError()
			}

		} else {
			// insert/update
			
			// remove `deletedKey` from SQL Entity dictionary
			var sqlDictionary = entityDictionary
			sqlDictionary.removeValue(forKey: deletedKey)
			
			// flatten array values into string list
			sqlDictionary = sqlDictionary.mapValues { value in
				if let collection  = value as? AnyCollection<Any> {
					return collection.map { String(describing: $0) }.joined(separator: ",")
			} else {
					return value
				}
			}
			
			let keys = sqlDictionary.keys
			
			let sqlInsertList = keys.map { "\"\($0)\"" }.joined(separator: ",")
			let sqlParemetersList = keys.map { ":\($0)" }.joined(separator: ",")
			
			let sql = "INSERT OR REPLACE INTO \(name)(\(sqlInsertList)) VALUES(\(sqlParemetersList))"
			
			// execute SQL
			guard self.db.executeUpdate(sql, withParameterDictionary: sqlDictionary ) else {
				throw self.db.lastError()
			}
		}
		
	}
	
	/// Executes block in the manager sync queue
	///
	/// - Parameter block: Block to execute
	/// - Throws: `rethrows` block exception
	@nonobjc open func inQueue<T>(_ block: @escaping () throws -> T) throws -> T {
		
		var blockError : Error?
		var result : T!
		
		self.inSyncQueue {
			do {
				result = try block()
			} catch {
				blockError = error
			}
		}
		
		if let err = blockError {
			throw err
		}
		
		return result
	}
}
