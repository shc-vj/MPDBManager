//
//  RRFTS3ExtensionLoader.m
//  sqlite-fts3-extension
//
//  Created by Evan Schoenberg on 6/28/10.
//  Copyright 2010 Evan Schoenberg. All rights reserved.
//

#import "RRFTS3ExtensionLoader.h"

#include <sqlite3.h>

static void rankfunc(sqlite3_context *pCtx, int nVal, sqlite3_value **apVal){
    unsigned int *aMatchinfo;                /* Return value of matchinfo() */
    int nCol;                       /* Number of columns in the table */
    int nPhrase;                    /* Number of phrases in the query */
    int iPhrase;                    /* Current phrase */
    double score = 0.0;             /* Value to return */
    
    assert( sizeof(int)==4 );
    
    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table.
     */
    if( nVal<1 ) goto wrong_number_args;
    aMatchinfo = (unsigned int *)sqlite3_value_blob(apVal[0]);
    nPhrase = aMatchinfo[0];
    nCol = aMatchinfo[1];
    if( nVal!=(1+nCol) ) goto wrong_number_args;
    
    /* Iterate through each phrase in the users query. */
    for(iPhrase=0; iPhrase<nPhrase; iPhrase++){
        int iCol;                     /* Current column */
        
        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in 
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        unsigned int *aPhraseinfo = &aMatchinfo[2 + iPhrase*nCol*3];
        for(iCol=0; iCol<nCol; iCol++){
            int nHitCount = aPhraseinfo[3*iCol];
            int nGlobalHitCount = aPhraseinfo[3*iCol+1];
            double weight = sqlite3_value_double(apVal[iCol+1]);
            if( nHitCount>0 ){
                score += ((double)nHitCount / (double)nGlobalHitCount) * weight;
            }
        }
    }
    
    sqlite3_result_double(pCtx, score);
    return;
    
    /* Jump here if the wrong number of arguments are passed to this function */
wrong_number_args:
    sqlite3_result_error(pCtx, "wrong number of arguments to function rank()", -1);
}


@implementation RRFTS3ExtensionLoader

+ (void)loadFTS3
{
	/*
	 * Note that we're calling sqlite3Fts3Init() directly. We're a static library,
	 * so we'll ultimately be loaded alongside sqlite3 itself. This auto_extension call
	 * is as if we were compiled as part of the amalgamation.
	 */
//	sqlite3_auto_extension ((void (*)(void)) sqlite3Fts3Init);
}

+ (BOOL)registerRankFunctionWithConnection:(struct sqlite3*)db
{
    int error = sqlite3_create_function(db, "rank", -1, SQLITE_ANY, NULL,
                                        rankfunc, NULL, NULL);
    if( error != SQLITE_OK ) {
        NSLog(@"ERROR: sqlite_create_function");
        return NO;
    }
    
    return YES;
}

@end
