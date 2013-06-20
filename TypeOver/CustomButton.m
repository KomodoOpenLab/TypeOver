//
//  CustomButton.m
//  TypeOver
//
//  Created by Owen McGirr on 24/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)accessibilityElementDidBecomeFocused {
    [self setBackgroundImage:[UIImage imageNamed:@"highlightedButton.png"] forState:UIControlStateNormal];
	startTime=[NSDate date];
}

- (void)accessibilityElementDidLoseFocus {
    [self setBackgroundImage:[UIImage imageNamed:@"normalButton.png"] forState:UIControlStateNormal];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"manual_scan_rate"]) {
		NSTimeInterval timeSince = [startTime timeIntervalSinceNow];
		float actualSpeed=timeSince*-1; // changes to a plus
		NSLog(@"%f", actualSpeed);
		[[NSUserDefaults standardUserDefaults] setFloat:actualSpeed forKey:@"scan_rate_float"];
	}
}

@end
