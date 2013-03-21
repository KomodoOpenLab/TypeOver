//
//  AppDelegate.h
//  XMLTest
//
//  Created by Tom Nantais on 13-03-20.
//  Copyright (c) 2013 Komodo Open Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSXMLParserDelegate>
{
    NSXMLParser *rssParser;
    NSMutableArray *articles;
    NSMutableDictionary *item;
    NSString *currentElement;
    NSMutableString *ElementValue;
    BOOL errorParsing;
    int count;
    NSDictionary *attribs;
    sqlite3 *database;
}

@property (assign) IBOutlet NSWindow *window;

@end
