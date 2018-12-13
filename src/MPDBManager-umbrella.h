#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FMDatabaseQueue+Database.h"
#import "FMDatabaseQueue+NoDatabaseOpen.h"
#import "MPDBManager.h"
#import "RRFTS3ExtensionLoader.h"

FOUNDATION_EXPORT double MPDBManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char MPDBManagerVersionString[];

