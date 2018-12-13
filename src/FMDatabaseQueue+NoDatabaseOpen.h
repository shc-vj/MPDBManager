//
//  FMDatabaseQueue+NoDatabaseOpen.h
//  Empendium
//
//  Created by pawelc on 28/07/16.
//  Copyright © 2016 Medycyna Praktyczna. All rights reserved.
//

#import "FMDatabaseQueue.h"
#import <objc/runtime.h>

extern const void * const kDispatchQueueSpecificKey;

/**
 Category redefines init* methods to not open database (open is deffered to the first database access)
 */
@interface FMDatabaseQueue (NoDatabaseOpen) 

@property (nonatomic, readonly) dispatch_queue_t dispatchQueue;

@end
