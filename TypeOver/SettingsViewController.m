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


static int scanRates[] = {5000, 4170, 3470, 2890, 2410, 2000, 1670, 1400, 1160, 970, 810, 670, 560, 480, 390, 320, 270};


- (void)viewDidLoad
{
    [super viewDidLoad];
    inputRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"];
	selRate = [[NSUserDefaults standardUserDefaults] integerForKey:@"scan_rate_int"];
	NSLog(@"%i", selRate);
	autoPred=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"];
	textSpeak=[[NSUserDefaults standardUserDefaults] boolForKey:@"text_pred"];
	autoPredAfter=[[NSUserDefaults standardUserDefaults] integerForKey:@"auto_pred_after"];
	manualDwellTime=[[NSUserDefaults standardUserDefaults] boolForKey:@"manual_scan_rate"];
	NSMutableString *st=[NSMutableString stringWithString:@"Predict after "];
	[st appendFormat:@"%i", autoPredAfter];
	if (autoPredAfter>1) {
		[st appendString:@" letters"];
	}
	else if (autoPredAfter==1) {
		[st appendString:@" letter"];
	}
	[autoPredAfterLabel setText:st];
	if (manualDwellTime) {
		manualDwellTimeToggleSwitch.on=true;
	}
	else {
		manualDwellTimeToggleSwitch.on=false;
		[dwellTimeLabel setHidden:YES];
		[dwellTimeDownButton setHidden:YES];
		[dwellTimeUpButton setHidden:YES];
		[aboutDwellTimeButton setHidden:YES];
	}
	if (textSpeak) {
		textSpeakPredToggleSwitch.on=true;
		NSLog(@"text speak prediction on");
	}
	else {
		textSpeakPredToggleSwitch.on=false;
		NSLog(@"text speak prediction off");
	}
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
























// methods

- (void)scanIndicator {
	if (scanRateInd<=3) {
		if ([dwellTimeLabel.text isEqualToString:@"Dwell time"]||[dwellTimeLabel.text isEqualToString:@"rate of change"]) {
			[dwellTimeLabel setText:@"This is the..."];
		}
		else {
			[dwellTimeLabel setText:@"rate of change"];
		}
		scanRateInd++;
	}
	else {
		[dwellTimeLabel setText:@"Dwell time"];
		[scanRateIndicatorTimer invalidate];
		scanRateInd=0;
	}
}






















// button actions

- (IBAction)manualDwellTimeToggleAct:(id)sender {
	if (manualDwellTimeToggleSwitch.on) {
		manualDwellTime=true;
		[dwellTimeLabel setHidden:NO];
		[dwellTimeDownButton setHidden:NO];
		[dwellTimeUpButton setHidden:NO];
		[aboutDwellTimeButton setHidden:NO];
		NSLog(@"manual dwell time on");
	}
	else {
		manualDwellTime=false;
		[dwellTimeLabel setHidden:YES];
		[dwellTimeDownButton setHidden:YES];
		[dwellTimeUpButton setHidden:YES];
		[aboutDwellTimeButton setHidden:YES];
		NSLog(@"manual dwell time off");
	}
}

- (IBAction)dwellTimeDownAct:(id)sender {
	bool valueFound = NO;
	int i = 0;
	while (!valueFound && i<17) {
		if (scanRates[i]==selRate) {
			valueFound=YES;
		}
		else {
			i++;
		}
	}
	if (i<17) {
		i++;
		selRate=scanRates[i];
		inputRate=(float)(selRate)/1000;
		NSLog(@"%f", inputRate);
	}
	[scanRateIndicatorTimer invalidate];
	scanRateInd=0;
	scanRateIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(scanIndicator) userInfo:nil repeats:YES];
}

- (IBAction)dwellTimeUpAct:(id)sender {
	bool valueFound = NO;
	int i = 0;
	while (!valueFound && i<17) {
		if (scanRates[i]==selRate) {
			valueFound=YES;
		}
		else {
			i++;
		}
	}
	if (i>1) {
		i--;
		selRate=scanRates[i];
		inputRate=(float)(selRate)/1000;
		NSLog(@"%f", inputRate);
	}
	[scanRateIndicatorTimer invalidate];
	scanRateInd=0;
	scanRateIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(scanIndicator) userInfo:nil repeats:YES];
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

- (IBAction)textSpeakPredToggleAct:(id)sender {
	if ([textSpeakPredToggleSwitch isOn]) {
		textSpeak=true;
	}
	else {
		textSpeak=false;
	}
}

- (IBAction)fontSizeDownAct:(id)sender {
	
}

- (IBAction)fontSizeUpAct:(id)sender {
	
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
		[[NSUserDefaults standardUserDefaults] setBool:manualDwellTime forKey:@"manual_scan_rate"];
		[[NSUserDefaults standardUserDefaults] setBool:textSpeak forKey:@"text_pred"];
		[[NSUserDefaults standardUserDefaults] setBool:autoPred forKey:@"auto_pred"];
		[[NSUserDefaults standardUserDefaults] setFloat:inputRate forKey:@"scan_rate_float"];
		[[NSUserDefaults standardUserDefaults] setInteger:selRate forKey:@"scan_rate_int"];
		[[NSUserDefaults standardUserDefaults] setInteger:autoPredAfter forKey:@"auto_pred_after"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		NSLog(@"settings saved");
    }
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

- (IBAction)aboutManualDwellTimeAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
													message:@"Dwell time is the rate at which the keypad keys cycle through their content. Dwell time can be automatically set by your Tecla Shield or other switch interface. To do this, simply switch manual dwell time off. Or, if you would rather set dwell time manually, switch it on."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
}

- (IBAction)aboutTextSpeakPredAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
													message:@"Text speak prediction provides the ability for you to just type key letters from the word you want. For example, typing 'pbl' would predict 'probably'. For optimum results, type the most distinctive letters in the word. You have to include the first letter. Also, the letters must be in the correct order."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
}

- (IBAction)aboutFontSizeAct:(id)sender {
}

@end
