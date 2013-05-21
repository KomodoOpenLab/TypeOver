//
//  SettingsViewController.m
//  TypeOver
//
//  Created by Owen McGirr on 24/03/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    inputRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"in_rate"];
	autoPred=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"];
	autoPredAfter=[[NSUserDefaults standardUserDefaults] integerForKey:@"autopred_after"];
	NSMutableString *st=[NSMutableString stringWithString:@"Predict after "];
	[st appendFormat:@"%i", autoPredAfter];
	if (autoPredAfter>1) {
		[st appendString:@" letters"];
	}
	else if (autoPredAfter==1) {
		[st appendString:@" letter"];
	}
	[autoPredAfterLabel setText:st];
	if (autoPred) {
		autoPredToggleSwitch.on=true;
	}
	else {
		autoPredToggleSwitch.on=false;
		[autoPredAfterLabel setHidden:YES];
		[autoPredAfterDownButton setHidden:YES];
		[autoPredAfterUpButton setHidden:YES];
		[aboutAutoPredAfterButton setHidden:YES];
	}
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}








// button actions 

- (IBAction)dwellTimeDownAct:(id)sender {
    inputRate = inputRate + 0.5;
}

- (IBAction)dwellTimeUpAct:(id)sender {
    if (inputRate > 0.5) {
        inputRate = inputRate - 0.5;
    }
}

- (IBAction)autoPredictToggleAct:(id)sender {
	if (autoPredToggleSwitch.on) {
		autoPred=true;
		[autoPredAfterLabel setHidden:NO];
		[autoPredAfterDownButton setHidden:NO];
		[autoPredAfterUpButton setHidden:NO];
		[aboutAutoPredAfterButton setHidden:NO];
		NSLog(@"auto predict on");
	}
	else {
		autoPred=false;
		[autoPredAfterLabel setHidden:YES];
		[autoPredAfterDownButton setHidden:YES];
		[autoPredAfterUpButton setHidden:YES];
		[aboutAutoPredAfterButton setHidden:YES];
		NSLog(@"auto predict off");
	}
}

- (IBAction)autoPredAfterDownAct:(id)sender {
	if (autoPredAfter>1) {
		autoPredAfter=autoPredAfter-1;
	}
	NSMutableString *st=[NSMutableString stringWithString:@"Predict after "];
	[st appendFormat:@"%i", autoPredAfter];
	if (autoPredAfter>1) {
		[st appendString:@" letters"];
	}
	else if (autoPredAfter==1) {
		[st appendString:@" letter"];
	}
	[autoPredAfterLabel setText:st];
}

- (IBAction)autoPredAfterUpAct:(id)sender {
	if (autoPredAfter<4) {
		autoPredAfter=autoPredAfter+1;
		NSMutableString *st=[NSMutableString stringWithString:@"Predict after "];
		[st appendFormat:@"%i", autoPredAfter];
		if (autoPredAfter>1) {
			[st appendString:@" letters"];
		}
		else if (autoPredAfter==1) {
			[st appendString:@" letter"];
		}
		[autoPredAfterLabel setText:st];
	}
}

- (IBAction)saveAct:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:autoPred forKey:@"auto_pred"];
	[[NSUserDefaults standardUserDefaults] setFloat:inputRate forKey:@"in_rate"];
	[[NSUserDefaults standardUserDefaults] setInteger:autoPredAfter forKey:@"autopred_after"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)aboutDwellTimeAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
													message:@"Dwell time is the rate at which the keypad keys cycle through their content."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
}

- (IBAction)aboutAutoPredAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
													message:@"Auto predict means that word prediction will automatically appear after you input a number of letters."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
}

- (IBAction)aboutPredAfterAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
													message:@"This number can range from 1 to 4."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
}
@end
