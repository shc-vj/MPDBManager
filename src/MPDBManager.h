//
//  MPDBManager.h
//  MPICD10test
//
//  Created by pawelc on 12-02-17.
//  Copyright 2012 Metasprint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue+NoDatabaseOpen.h"
#import "FMDatabase.h"
#import <sqlite3.h>

/**
 Define FTS_EXTERNAL to use external SQLite FTS library
 */

@interface MPDBManager : NSObject

@property (nonatomic, readonly, nonnull) FMDatabaseQueue *queue;
@property (nonatomic, readonly, nonnull) FMDatabase *db;

@property (nonatomic, readonly) BOOL isInTransaction;

#ifdef FTS_EXTERNAL
+ (void)FTSinit;
#endif

+ (BOOL)isFTSsupported;
+ (BOOL)isWALsupported;

+ (void)closeAllManagersConnectedToSameDatabaseAsManager:(nonnull MPDBManager*)dbManager;

- (nonnull instancetype)init;
- (nonnull instancetype)initWithSQLiteOpenFlags:(int)flags;

- (nonnull instancetype)initWithDBPath:(nonnull NSString*)path;
- (nonnull instancetype)initWithDBPath:(nonnull NSString*)path SQLiteOpenFlags:(int)flags;

// open connection to database and setup connection dependent stuff
- (BOOL)openDatabase;
- (void)closeDatabase;

- (BOOL)beginTransaction;
- (BOOL)commitTransaction;
- (BOOL)rollbackTransaction;


- (void)inSyncQueue:(void(^_Nonnull)())block;

@end


@interface MPDBManager (DBPath)

+ (nonnull NSString*)dbFileName;
+ (nonnull NSString*)dbPath;
+ (nonnull NSString*)dbDirectoryPath;

+ (BOOL)createDatabasesDirectory;

+ (nonnull dispatch_queue_t)dispatchQueueForPath:(nonnull NSString*)path;
+ (void)releaseDispatchQueueForPath:(nonnull NSString*)path;

/**
 Add DB manager to list of managers using the same database path
 
 @param dbManager	Database manager
 @param path			Path to database file
 
 @return Number of managers currently using the same database path
 */
+ (NSUInteger)addDBManager:(nonnull MPDBManager*)dbManager toPath:(nonnull NSString*)path;

+ (nullable NSSet*)dbManagersAtPath:(nonnull NSString*)path;

/**
 Removes DBManager from list of managers using the same database path
 
 @param dbManger	DBManager
 @param path		Database file path
 
 @return Returns number of DBManagers left using the same database path
 */
+ (NSUInteger)removeDBManager:(nonnull MPDBManager*)dbManger fromPath:(nonnull NSString*)path;

@end
