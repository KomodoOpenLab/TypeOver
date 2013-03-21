//
//  AppDelegate.m
//  XMLTest
//
//  Created by Tom Nantais on 13-03-20.
//  Copyright (c) 2013 Komodo Open Lab. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BOOL bSuccess = YES;
    int result = 0;
    NSString *URL = @"file:///Users/tomnantais/Desktop/en_wordlist.xml";
    NSString *agentString = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:URL]];
    [request setValue:agentString forHTTPHeaderField:@"User-Agent"];
    NSData* xmlFile = [ NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil ];
    
    //open the database that will hold the word data
    result = sqlite3_open("/Users/tomnantais/Desktop/EnWords", &database);
    if (SQLITE_OK!=result)
    {
        NSLog(@"couldn't open database result=%d",result);
        bSuccess = NO;
    }
    
    if (bSuccess)
    {
        char *errMsg = NULL;
        
        const char *dropSQL = "DROP TABLE WORDS";
        result = sqlite3_exec(database, dropSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error dropping WORDS table: %s",errMsg);
            //bSuccess = NO; //not necessarily fatal
        }
        
        const char *createSQL = "CREATE TABLE WORDS(ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, FREQUENCY INTEGER);";
        result = sqlite3_exec(database, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating WORDS table: %s",errMsg);
            bSuccess = NO;
        }
    }
    
    if (bSuccess)
    {
        errorInserting = NO;
        errorParsing=NO;
        count = 0;
        
        rssParser = [[NSXMLParser alloc] initWithData:xmlFile];
        [rssParser setDelegate:self];
        
        // You may need to turn some of these on depending on the type of XML file you are parsing
        [rssParser setShouldProcessNamespaces:NO];
        [rssParser setShouldReportNamespacePrefixes:NO];
        [rssParser setShouldResolveExternalEntities:NO];
        
        [rssParser parse];
    }
    
    sqlite3_close(database);

}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"File found and parsing started");
    
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *errorString = [NSString stringWithFormat:@"Error code %ld", [parseError code]];
    NSLog(@"Error parsing XML: %@", errorString);
    
    
    errorParsing=YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    currentElement = [elementName copy];
    ElementValue = [[NSMutableString alloc] init];
    attribs = [attributeDict copy];
    
    if ([elementName isEqualToString:@"w"]) {
        item = [[NSMutableDictionary alloc] init];
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [ElementValue appendString:string];
}

- (BOOL)addNewWord:(NSString*)wordstr withFreq:(int)freq
{
    BOOL bSuccess = YES;
    char* ins = "INSERT INTO WORDS (WORD, FREQUENCY) VALUES(?, ?);";
    
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(database,ins,-1,&stmt,nil)!=SQLITE_OK)
    {
        NSLog(@"failed to prepare");
        bSuccess = NO;
    }
    if(bSuccess)
    {
        sqlite3_bind_text(stmt, 1, [wordstr UTF8String], -1, NULL);
        sqlite3_bind_int(stmt, 2, freq);
        if (SQLITE_DONE!=sqlite3_step(stmt))
        {
            NSLog(@"failed to step");
            bSuccess = NO;
        }
    }
    
    sqlite3_finalize(stmt);
    
    return(bSuccess);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"w"]) {
        
        NSString* strFreq = [attribs objectForKey:@"f"];
        int nFreq = [strFreq intValue];
        
        if (!errorInserting)
        {
            if (![self addNewWord:ElementValue withFreq:nFreq])
            {
                errorInserting = YES;
            }
        
            count++;
            
            if (0==count%1000)
            {
                NSLog(@"%d passes",count);
            }
        }
    } else {
        [item setObject:ElementValue forKey:elementName];
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (errorParsing == NO)
    {
        NSLog(@"XML processing done!");
        NSLog(@"Total number of words: %d",count);
    } else {
        NSLog(@"Error occurred during XML processing");
    }
    
}



@end
