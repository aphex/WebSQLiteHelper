//
//  WebSQLiteHelper.h
//  WebSQLiteTest
//
//  Created by iphonedev on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVURLProtocol.h>
#import "sqlite3.h"

@interface WebSQLiteHelper : CDVPlugin 

- (void) checkExistence:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) create:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end