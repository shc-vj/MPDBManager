//
//  MPDBManager.m
//  MPICD10test
//
//  Created by pawelc on 12-02-17.
//  Copyright 2012 Metasprint. All rights reserved.
//

#import "MPDBManager.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue+Database.h"

// SQLite FTS search
#import "RRFTS3ExtensionLoader.h"

#import <Foundation/NSObjCRuntime.h>


@implementation MPDBManager

/**
 Dictionary with path as keys and boxed `dispatch_queue_t` as values
 */
static NSMutableDictionary<NSString*,dispatch_queue_t> *MPDBManager_sharedDispatchQueues = nil;
/**
 Dictionary with path as keys and values are sets with MPDBManagers connecting to database at this path
 */
static NSMutableDictionary<NSString*,NSMutableSet<MPDBManager*>*> *MPDBManager_managersAtPaths = nil;

static BOOL MPDBManager_FTS3_support = NO;
static BOOL MPDBManager_WAL_support = NO;

@synthesize queue = _queue;

+ (void)initialize
{
	
	if( self != MPDBManager.class ) {
		// prevent subclasses
		return;
	}
	
	MPDBManager_sharedDispatchQueues = [NSMutableDictionary dictionary];
	MPDBManager_managersAtPaths = [NSMutableDictionary dictionary];
	
	const char *FTS_enable = "ENABLE_FTS3";
	
	if( &sqlite3_compileoption_get ) {	// check symbol binding
		for( int i=0; i<200; i++ ) {
			const char *opt = sqlite3_compileoption_get(i);
			if( opt == NULL )
				break;
			
			if( strcmp( opt, FTS_enable) == 0 ) {
				MPDBManager_FTS3_support = YES;
			}
		}
	}
	
	NSString *sqliteVer = [FMDatabase sqliteLibVersion];
	
	// versions of SQLite newer or equal 3.7.0 have WAL support
	NSComparisonResult result = [sqliteVer compare:@"3.7.0" options:NSNumericSearch];
	if(  result == NSOrderedDescending || result == NSOrderedSame ) {
		NSLog(@"Database WAL journal supported");
		MPDBManager_WAL_support = YES;
	}
}

+ (BOOL)isFTSsupported
{
	return MPDBManager_FTS3_support;
}

+ (BOOL)isWALsupported
{
	return MPDBManager_WAL_support;
}

+ (void)closeAllManagersConnectedToSameDatabaseAsManager:(MPDBManager*)dbManager
{
	@synchronized (MPDBManager_managersAtPaths) {
		NSMutableSet<MPDBManager*> *managersAtPath = [MPDBManager_managersAtPaths objectForKey:dbManager.queue.path];

		[managersAtPath enumerateObjectsUsingBlock:^(MPDBManager * _Nonnull obj, BOOL * _Nonnull stop) {
			[obj closeDatabase];
		}];
	}
}

#ifdef FTS_EXTERNAL
+ (void)FTSinit
{
	static BOOL MPDBManager_IsFTSInitialized = NO;

	if( NO == MPDBManager_IsFTSInitialized ) {
		
		if( MPDBManager_FTS3_support == NO ) {
			// check again
			NSString *sqliteVer = [FMDatabase sqliteLibVersion];
			
			// in new versions of SQLite we must not initialize this extension
			if( [sqliteVer compare:@"3.7.13" options:NSNumericSearch] == NSOrderedAscending )
			{
				//initilize FTS extension
				[RRFTS3ExtensionLoader loadFTS3];
				
				MPDBManager_FTS3_support = YES;
			}
		}
		
		MPDBManager_IsFTSInitialized = YES;
	}	
}
#endif


#pragma mark - Init

- (instancetype)init
{
	return [self initWithSQLiteOpenFlags:SQLITE_OPEN_READWRITE];		// do not create
}

- (instancetype)initWithSQLiteOpenFlags:(int)flags;
{
	NSString *path = [[self class] dbPath];
	self = [self initWithDBPath:path SQLiteOpenFlags:flags];
	
	return self;
}

- (instancetype)initWithDBPath:(NSString*)path
{
	return [self initWithDBPath:path SQLiteOpenFlags:SQLITE_OPEN_READWRITE];		// do not create
}

- (nonnull instancetype)initWithDBPath:(nonnull NSString*)path SQLiteOpenFlags:(int)flags
{
	self = [super init];
	if( self ) {
		_queue = [[FMDatabaseQueue alloc] initWithPath:path flags:flags];
		
		NSUInteger numberOfManagersAtPath = [self.class addDBManager:self toPath:path];
		if( numberOfManagersAtPath > 1 ) {
			// an additional sync queue is needed only for more than one manager
			dispatch_queue_t targetDispatchQueue = [self.class dispatchQueueForPath:path];

			if( numberOfManagersAtPath == 2 ) {
				// previous manager does not have set a proper queue, so fix it
				// also set shared queue for this db manager (it is already in a list)
				for( MPDBManager *dbManager in [self.class dbManagersAtPath:path] ) {
					dispatch_set_target_queue(dbManager.queue.dispatchQueue, targetDispatchQueue);
				}
			} else {
				// previous managers have already set proper queue
				// so we need to set one only for this manager
				dispatch_set_target_queue(_queue.dispatchQueue, targetDispatchQueue);
			}
		}
		
#ifdef FTS_EXTERNAL
		[[self class] FTSinit];
#endif
		
	}
	
	return self;
}


#pragma mark - Porperties


- (FMDatabase*)db
{
	return self.queue.database;
}

#pragma mark - Database access

// open connection to database and setup connection dependent stuff
- (BOOL)openDatabase
{
#if SQLITE_VERSION_NUMBER >= 3005000
	BOOL success = [self.db openWithFlags:self.queue.openFlags vfs:self.queue.vfsName];
#else
	BOOL success = [self.db open];
#endif

	
	if( !success ) {
		NSLog(@"ERROR: DB manager %@ (openDatabase %@)", NSStringFromClass([self class]), self.queue.path );
		return NO;
	} else {
		[self.db setMaxBusyRetryTimeInterval:1.0];
		
		// register FTS rank function
		if( ![RRFTS3ExtensionLoader registerRankFunctionWithConnection:[self.db sqliteHandle]] ) {
			NSLog(@"ERROR: Cannot register SQLite function");				
		}
	}
	
	return YES;
}

- (void)closeDatabase
{
	[self.queue close];
}

- (BOOL)isInTransaction
{
	return [self.db isInTransaction];
}


- (BOOL)beginTransaction
{
	if( [self.class isWALsupported] ) {
		NSString *update = @"PRAGMA journal_mode=WAL; PRAGMA journal_size_limit=0;";
		BOOL WAL = [self.db executeStatements:update];
		if( WAL ) {
			NSLog(@"Database journal_mode=WAL");
		}
	}

	return [self.db beginTransaction];
}

- (BOOL)commitTransaction
{
	return [self.db commit];
}

- (BOOL)rollbackTransaction
{
	return [self.db rollback];
}


- (void)dealloc
{
	[self closeDatabase];
	
	NSUInteger numberOfManagersLeftAtPath = [self.class removeDBManager:self fromPath:self.queue.path];
	if( numberOfManagersLeftAtPath == 0 ) {
		// remove the dispatch queue
		[self.class releaseDispatchQueueForPath:self.queue.path];
	}
}
		
- (void)inSyncQueue:(void(^)())block
{
	/* Get the currently executing queue (which should probably be nil, but in theory could be another DB queue
	 * and then check it against self to make sure we're not about to deadlock. */
	FMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
	
	if( currentSyncQueue != self.queue ) {
		[self.queue inDatabase:^(FMDatabase *db) {
			block();
		}];
	} else {
		block();
	}
}
					
@end


@implementation MPDBManager (DBPath)



+ (NSString*)dbFileName
{
    return @"db.db";	
}

+ (NSString*)dbPath
{
	NSString *name = [self dbFileName];
	
	NSString *dbDirectory = [self dbDirectoryPath];
	
	return [dbDirectory stringByAppendingPathComponent:name];
}

+ (nonnull NSString*)dbDirectoryPath
{
	
	NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	
	NSString *dbDirectory = [appSupportPath stringByAppendingPathComponent:@"databases"];
	
	return dbDirectory;
}

+ (BOOL)createDatabasesDirectory
{
 	NSString *directoryPath = [self dbDirectoryPath];
	BOOL success = [NSFileManager.defaultManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	if( success ) {
		NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
		
		success = [directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];

	}
	
	return success;
}

+ (dispatch_queue_t)dispatchQueueForPath:(NSString*)path
{
	@synchronized (MPDBManager_sharedDispatchQueues) {
		
		dispatch_queue_t queue = [MPDBManager_sharedDispatchQueues objectForKey:path];
		
		if( nil == queue ) {
			// create new one
			queue = dispatch_queue_create([[NSString stringWithFormat:@"MPDBManager.%@", [path lastPathComponent]] UTF8String], NULL);
			dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
			
			[MPDBManager_sharedDispatchQueues setValue:queue forKey:path];
		}
		
		return queue;
	}
}

+ (void)releaseDispatchQueueForPath:(NSString*)path
{
	@synchronized (MPDBManager_sharedDispatchQueues) {
		
		[MPDBManager_sharedDispatchQueues removeObjectForKey:path];
	}
}

+ (NSUInteger)addDBManager:(nonnull MPDBManager*)dbManager toPath:(nonnull NSString*)path
{
	@synchronized (MPDBManager_managersAtPaths) {
		NSMutableSet *managersAtPath = [MPDBManager_managersAtPaths objectForKey:path];
		
		if( nil == managersAtPath ) {
			// create array
			managersAtPath = [NSMutableSet set];
		}
		
		[managersAtPath addObject:dbManager];
		
		[MPDBManager_managersAtPaths setObject:managersAtPath forKey:path];
		
		return managersAtPath.count;
	}
}
	
+ (nullable NSSet*)dbManagersAtPath:(nonnull NSString*)path
{
	@synchronized (MPDBManager_managersAtPaths) {
		return [MPDBManager_managersAtPaths objectForKey:path];
	}
}


+ (NSUInteger)removeDBManager:(nonnull MPDBManager*)dbManger fromPath:(nonnull NSString*)path
{
	@synchronized (MPDBManager_managersAtPaths) {
		NSMutableSet *managersAtPath = [MPDBManager_managersAtPaths objectForKey:path];
		
		if( nil == managersAtPath ) {
			// NOP
			return 0;
		}
		
		[managersAtPath removeObject:dbManger];
		
		if( managersAtPath.count == 0 ) {
			// none of the managers is connected with path
			[MPDBManager_managersAtPaths removeObjectForKey:path];
		}
		
		return managersAtPath.count;
	}
}


@end
