//
//  CustomButton.m
//  TypeOver
//
//  Created by Owen McGirr on 24/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton


static int scanRates[] = {5000, 4170, 3470, 2890, 2410, 2000, 1670, 1400, 1160, 970, 810, 670, 560, 480, 390, 320, 270};


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
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"manual_scan_rate"]&&![shieldTimer isValid]) {
		shieldRate=0;
		shieldTimer=[NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(incrementRate) userInfo:nil repeats:YES];
	}
}

- (void)accessibilityElementDidLoseFocus {
    [self setBackgroundImage:[UIImage imageNamed:@"normalButton.png"] forState:UIControlStateNormal];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"manual_scan_rate"]&&[shieldTimer isValid]) {
		[shieldTimer invalidate];
		int difference, index;
		index =0;
		for( int i = 0; i < 17; i++ )
		{
			if (difference > abs( shieldRate - scanRates [ i ] ))
			{
				difference = abs( shieldRate - scanRates [ i ] );
				index = i;
			}
			else {
				shieldRate=scanRates[i];
			}
		}
		[[NSUserDefaults standardUserDefaults] setFloat:(float)(shieldRate)/1000 forKey:@"scan_rate_float"];
	}
}

- (void)incrementRate {
	shieldRate++;
}

@end
