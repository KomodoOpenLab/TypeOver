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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
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
	// initialise graphics session 
	
	UIGraphicsBeginImageContext([self bounds].size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	
	// fill rect with color
	
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, [self bounds]);
	
	
	// draw radial gradient
	
	CGRect gradientRect = CGRectMake(self.bounds.origin.x + 0.2, self.bounds.origin.y + 0.2, self.bounds.size.width - 0.4, self.bounds.size.height - 0.4);
	CGContextClipToRect(context, gradientRect);
	
	CGColorSpaceRef colourspace = CGColorSpaceCreateDeviceRGB();
	CGFloat *bComponents = NULL;
	if (color==[UIColor blackColor]) {
		bComponents = (CGFloat[12]) {
			0.2, 0.2, 0.2, 1.0,
			0.2, 0.2, 0.2, 1.0,
			0.12, 0.12, 0.12, 1.0
		};
	}
	else if (color==[UIColor blueColor]) {
		bComponents = (CGFloat[12]) {
			0.3, 0.3, 255.0, 1.0,
			0.3, 0.3, 255.0, 1.0,
			0.0, 0.0, 255.0, 1.0
		};
	}
	
	CGFloat bGlocations[] = {0.0, 0.5, 1.0};
	
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colourspace, bComponents, bGlocations, 3);
	
	CGPoint centerPoint = CGPointMake(gradientRect.size.width/2, gradientRect.size.height/2);
	CGContextDrawRadialGradient(context, gradient, centerPoint, 0.0, centerPoint, CGRectGetWidth(gradientRect)*0.7, kCGGradientDrawsBeforeStartLocation);
	
	
	// set button background
	
	[self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
	
	
	// end graphics session
	
	UIGraphicsEndImageContext();
}

@end
