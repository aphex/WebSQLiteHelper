//
//  WebSQLiteHelper.m
//  WebSQLiteTest
//
//  Created by iphonedev on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebSQLiteHelper.h"


@implementation WebSQLiteHelper

- (NSString *) appDatabasePath {
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDir = [libraryPaths objectAtIndex:0];
    return [libraryDir stringByAppendingPathComponent:@"Caches/"];   
}

- (NSString *) masterDatabasePath {
    NSString *masterName = @"Databases.db";
    NSString *appDatabasePath = [self appDatabasePath];
    return [appDatabasePath stringByAppendingPathComponent:masterName];
}

- (BOOL) masterDatabaseExists {
    NSString *masterFile = [self masterDatabasePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager fileExistsAtPath:masterFile];   
    [fileManager release];
    return success;
}

- (NSString *) getDatabasePath:(NSString *)dbName {
    
    NSString *path = nil;
    BOOL success = [self masterDatabaseExists];
    if(!success) return path;

    sqlite3 *database;
    if(sqlite3_open([[self masterDatabasePath] UTF8String], &database) == SQLITE_OK) {
        const char *sqlStatement = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IS 'Databases'";
        sqlite3_stmt *compiledStatement;
        int count= 0;
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
            while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                count = sqlite3_column_int(compiledStatement, 0);
            }
            sqlite3_finalize(compiledStatement);
            
            if(count >= 0){                    
                NSString *sqlStatement = [NSString stringWithFormat:@"SELECT origin, name, path FROM Databases WHERE name IS '%@'%", dbName];
                sqlite3_stmt *compiledStatement;
                if(sqlite3_prepare_v2(database, [sqlStatement cStringUsingEncoding:NSASCIIStringEncoding], -1, &compiledStatement, NULL) == SQLITE_OK) {
                    while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                        NSString *aOrigin = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                        NSString *aPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
                        
                        NSString *appDatabasePath = [self appDatabasePath];
                        path =[[appDatabasePath stringByAppendingPathComponent:aOrigin] stringByAppendingPathComponent:aPath]; 
                    }
                }
            }
        }
        
        sqlite3_close(database);
    }
    return path;
}

- (void) checkExistence:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options { 
    NSLog(@"Called checkExistence");
    NSString* callback = [arguments objectAtIndex:0];
    NSString* dbName = [arguments objectAtIndex:1];
    
    
    CDVPluginResult* pluginResult;
    
    NSString* path = [self getDatabasePath:dbName];
    if(path == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:false];   
    }else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager fileExistsAtPath:path];
        [fileManager release];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:success];
    }
    
    [self writeJavascript:[pluginResult toSuccessCallbackString:callback]];
}

- (void) create:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options { 
        NSLog(@"Called Create");
    CDVPluginResult* pluginResult;
    NSString* callback = [arguments objectAtIndex:0];
    NSString* dbName = [arguments objectAtIndex:1];
    NSString* srcFile = [arguments objectAtIndex:2];
    
    if(![self masterDatabaseExists]){
            NSLog(@"Called No Master Database");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error Master Database Does not Exist"];
    }else{
        NSString* dbPath = [self getDatabasePath:dbName];
        if(dbPath == nil){
                        NSLog(@"Called No Database at Path");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error Database was not initalized"];            
        }else{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString* srcPath = [NSString stringWithFormat:@"%@/www/%@",[[NSBundle mainBundle] bundlePath],srcFile ];
            NSError* error;

            NSLog([NSString stringWithFormat:@"Deleting: %@", dbPath]);
            if(![fileManager removeItemAtPath:dbPath error:&error]){
                NSLog(@"Error Removing File");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error removing existing DB"];
            }else{
                if(![fileManager copyItemAtPath:srcPath toPath:dbPath error:&error]){
                    NSLog(@"Copy Error");
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error Copying Database"];
                }else{
                    NSLog(@"Copy Successful");
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:srcPath];
                }
            }
            [fileManager release];
        }
    }
    
    [self writeJavascript:[pluginResult toSuccessCallbackString:callback]];
}

@end
