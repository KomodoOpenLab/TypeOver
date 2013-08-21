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
		// set button appearance 
		[self styleButton:[UIColor blackColor]];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
		// set font autosize
		self.titleLabel.numberOfLines = 1;
		self.titleLabel.adjustsFontSizeToFitWidth = YES;
		self.titleLabel.lineBreakMode = NSLineBreakByClipping;
		
        // add event to button press
		[self addTarget:self action:@selector(touchButton) forControlEvents:UIControlEventAllTouchEvents];
    }
    return self;
}

- (void)accessibilityElementDidBecomeFocused {
	[self styleButton:[UIColor blueColor]];
	
	startTime=[NSDate date]; // gets actual time
}

- (void)accessibilityElementDidLoseFocus {
	[self styleButton:[UIColor blackColor]];
	
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


#pragma mark - drawing

- (void)styleButton:(UIColor *)color {
	// draw background image
	UIGraphicsBeginImageContext([self bounds].size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, CGRectMake(0.0, 0.0, [self bounds].size.width, [self bounds].size.height));
	
	// draw radial gradient
	CGColorSpaceRef colourspace = CGColorSpaceCreateDeviceRGB();
	CGFloat bComponents[] = {0.2, 0.2, 0.2, 0.8, 0.3, 0.3, 0.3, 0.2};
	CGFloat bGlocations[] = {0.0, 1.0};
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colourspace, bComponents, bGlocations, 2);
	CGPoint centerPoint = CGPointMake([self bounds].size.width/2, [self bounds].size.height/2);
	CGContextDrawRadialGradient(context, gradient, centerPoint, 0.0, centerPoint, CGRectGetWidth([self bounds]), kCGGradientDrawsBeforeStartLocation);
	
	// set button background
	[self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
	
	// end graphics session
	UIGraphicsEndImageContext();
}

@end
