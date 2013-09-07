//
//  CustomButton.m
//  TypeOver
//
//  Created by Owen McGirr on 24/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)


#pragma mark - button methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
		// set button appearance
		[self styleButton:[UIColor blackColor]];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
		// set font
		if (IS_IPAD) {
			[self.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:30.0]];
		}
		else {
			[self.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];
		}
		
		// set drop shadow
		[self setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
		[self.titleLabel setShadowOffset:CGSizeMake(2.5, 2.5)];
		
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
    
    CGContextSaveGState(context);
	
	
	// fill rect with color
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, [self bounds]);
	
	// draw radial gradient
	CGRect gradientRect = CGRectMake(self.bounds.origin.x + 0.2, self.bounds.origin.y + 0.2, self.bounds.size.width - 0.4, self.bounds.size.height - 0.4);
    CGFloat ratio = gradientRect.size.height/gradientRect.size.width;
    NSLog(@"ratio=%f",ratio);
	CGPoint centerPoint = CGPointMake(gradientRect.size.width/2.0, gradientRect.size.height/2.0/ratio);
	
    // apply an affine transform to scale y by the same factor as the aspect ratio of the key
	CGContextScaleCTM(context, 1.0, ratio);
    
	CGColorSpaceRef colourspace = CGColorSpaceCreateDeviceRGB();
	CGFloat *bComponents = NULL;
	if (color==[UIColor blackColor]) {
		bComponents = (CGFloat[12]) {
			0.2, 0.2, 0.2, 1.0,
			0.2, 0.2, 0.2, 1.0,
			0.14, 0.14, 0.14, 1.0
		};
	}
	else if (color==[UIColor blueColor]) {
		bComponents = (CGFloat[12]) {
			0.3, 0.3, 1.0, 1.0,
			0.3, 0.3, 1.0, 1.0,
			0.0, 0.0, 0.4, 1.0
		};
	}
	
	CGFloat bGlocations[] = {0.0, 0.1, 1.0};
	
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colourspace, bComponents, bGlocations, 3);
    
	CGContextDrawRadialGradient(context, gradient, centerPoint, 0.0, centerPoint, CGRectGetWidth(gradientRect), 0);
    
    CGContextRestoreGState(context);
    
    
    CGContextSetRGBStrokeColor(context, 0.15, 0.15, 0.15, 1.0);
    CGContextSetLineWidth(context,2.0);
    CGContextStrokeRect(context, self.bounds);
	
	
	// set button background
	[self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
	
	
	// end graphics session
	UIGraphicsEndImageContext();
}

@end
