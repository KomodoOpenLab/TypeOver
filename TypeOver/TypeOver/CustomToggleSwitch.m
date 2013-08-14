//
//  CustomToggleSwitch.m
//  TypeOver
//
//  Created by Owen McGirr on 12/08/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "CustomToggleSwitch.h"

@implementation CustomToggleSwitch


#pragma mark - toggle switch methods 

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
		// set switch appearance
		[self styleOn:[UIColor blackColor] styleOff:[UIColor grayColor]];
    }
    return self;
}

- (void)accessibilityElementDidBecomeFocused {
	// set switch appearance
	[self styleOn:[UIColor colorWithRed:0.31 green:0.1 blue:0.75 alpha:1.0] styleOff:[UIColor colorWithRed:0.31 green:0.1 blue:0.5 alpha:1.0]];
}

- (void)accessibilityElementDidLoseFocus {
	// set switch appearance
	[self styleOn:[UIColor blackColor] styleOff:[UIColor grayColor]];
}


#pragma mark - drawing

- (void)styleOn:(UIColor *)onColor styleOff:(UIColor *)offColor {
	// draw background image
	UIGraphicsBeginImageContext([self bounds].size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// on state
	CGContextSetFillColorWithColor(context, [onColor CGColor]);
	CGContextFillRect(context, CGRectMake(0.0, 0.0, [self bounds].size.width, [self bounds].size.height));
	[self setOnImage:UIGraphicsGetImageFromCurrentImageContext()];
	
	// off state 
	CGContextSetFillColorWithColor(context, [offColor CGColor]);
	CGContextFillRect(context, CGRectMake(0.0, 0.0, [self bounds].size.width, [self bounds].size.height));
	[self setOffImage:UIGraphicsGetImageFromCurrentImageContext()];
	
	// end graphics session
	UIGraphicsEndImageContext();
}
@end
