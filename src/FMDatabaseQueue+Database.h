//
//  FMDatabaseQueue+Database.h
//  NewPharmaDB
//
//  Created by pawelc on 12/05/16.
//  Copyright © 2016 Medycyna Praktyczna. All rights reserved.
//

@class  FMDatabase;

@interface FMDatabaseQueue (Database)

@property (nonatomic, strong, readonly, nonnull) FMDatabase *database;


@end
