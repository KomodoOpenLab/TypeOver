//
//  CustomButton.m
//  TypeOver
//
//  Created by Owen McGirr on 24/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton


#pragma mark - button methods 

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // add event to button press
		[self addTarget:self action:@selector(touchButton) forControlEvents:UIControlEventAllTouchEvents];
    }
    return self;
}

- (void)accessibilityElementDidBecomeFocused {
    [self setBackgroundImage:[UIImage imageNamed:@"highlightedButton.png"] forState:UIControlStateNormal];
	
	startTime=[NSDate date]; // gets actual time
}

- (void)accessibilityElementDidLoseFocus {
    [self setBackgroundImage:[UIImage imageNamed:@"normalButton.png"] forState:UIControlStateNormal];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"manual_scan_rate"]&&!didTouch) { // if manual dwell time is off and the button wasn't pressed
		NSTimeInterval timeSince = [startTime timeIntervalSinceNow];
		
		float actualSpeed=timeSince*-1; // changes to a plus
		NSLog(@"%f", actualSpeed);
		
		[[NSUserDefaults standardUserDefaults] setFloat:actualSpeed forKey:@"scan_rate_float"];
	}
	
	didTouch=false;
}

- (void)touchButton {
	didTouch=true;
	startTime=nil;
}

@end
