//
//  wordInfoStruct.h
//  TypeOver
//
//  Created by Thomas Nantais on 2013-09-10.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface wordInfoStruct : NSObject

@property NSString *word;
@property (assign) int unigramFreq;
@property (assign) int bigramFreq;
@end
