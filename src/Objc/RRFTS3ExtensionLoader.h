//
//  RRFTS3ExtensionLoader.h
//  sqlite-fts3-extension
//
//  Created by Evan Schoenberg on 6/28/10.
//  Copyright 2010 Evan Schoenberg. All rights reserved.
//

#import <Foundation/Foundation.h>

struct sqlite3;

@interface RRFTS3ExtensionLoader : NSObject {

}

+ (void)loadFTS3;
+ (BOOL)registerRankFunctionWithConnection:(struct sqlite3*)db;

@end
