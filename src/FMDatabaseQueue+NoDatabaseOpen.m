//
//  FMDatabaseQueue+NoDatabaseOpen.m
//  Empendium
//
//  Created by pawelc on 28/07/16.
//  Copyright © 2016 Medycyna Praktyczna. All rights reserved.
//

#import "FMDatabaseQueue+NoDatabaseOpen.h"
#import "FMDatabaseQueue+Database.h"
#import "FMDatabase.h"

#import <objc/runtime.h>

const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;

@implementation FMDatabaseQueue (NoDatabaseOpen)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName
{
	self = [super init];
	
	if (self) {
		
		FMDatabase *db = [[[self class] databaseClass] databaseWithPath:aPath];
		FMDBRetain(db);
		[self setValue:db forKey:@"db"];
		
		self.path = aPath;
		
		dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
		dispatch_queue_set_specific(queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);
		object_setInstanceVariable(self, "_queue", queue);
		
		[self setValue:@(openFlags) forKey:@"openFlags"];
		
		self.vfsName = vfsName;
	}
	
	return self;
}

#pragma clang diagnostic pop


- (dispatch_queue_t)dispatchQueue
{
	dispatch_queue_t queue;
	object_getInstanceVariable(self, "_queue", (void*)&queue);

	return queue;
}

@end
