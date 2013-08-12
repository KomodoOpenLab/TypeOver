//
//  ViewController.m
//  VoiceQualityTester
//
//  Created by Owen McGirr on 30/05/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize slt, slt8k, kal, kal16, rms, rms8k, awb, awb8k, timeawb, fliteController;




- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	voices = [[NSArray alloc] initWithObjects:@"Awb", @"Awb8k", @"Kal", @"Kal16", @"Rms", @"Rms8k", @"Slt", @"Slt8k", @"TimeAwb", nil];
	voicePicker.delegate=self;
}



-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)voicePicker
{
	//One column
	return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	//set number of rows
	return voices.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	//set item per row
	return [voices objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	voiceNumber=row;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sayAct:(id)sender {
	if (voiceNumber==0) {
		[self.fliteController say:textToSay.text withVoice:self.awb];
	}
	else if (voiceNumber==1) {
		[self.fliteController say:textToSay.text withVoice:self.awb8k];
	}
	else if (voiceNumber==2) {
		[self.fliteController say:textToSay.text withVoice:self.kal];
	}
	else if (voiceNumber==3) {
		[self.fliteController say:textToSay.text withVoice:self.kal16];
	}
	else if (voiceNumber==4) {
		[self.fliteController say:textToSay.text withVoice:self.rms];
	}
	else if (voiceNumber==5) {
		[self.fliteController say:textToSay.text withVoice:self.rms8k];
	}
	else if (voiceNumber==6) {
		[self.fliteController say:textToSay.text withVoice:self.slt];
	}
	else if (voiceNumber==7) {
		[self.fliteController say:textToSay.text withVoice:self.slt8k];
	}
	else if (voiceNumber==8) {
		[self.fliteController say:textToSay.text withVoice:self.timeawb];
	}
}

- (IBAction)keyboardDone:(id)sender {
	[sender resignFirstResponder];
}


- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
	return fliteController;
}

- (Awb *)awb {
	if (awb == nil) {
		awb = [[Awb alloc] init];
	}
	return awb;
}

- (Awb8k *)awb8k {
	if (awb8k == nil) {
		awb8k = [[Awb8k alloc] init];
	}
	return awb8k;
}

- (Kal *)kal {
	if (kal == nil) {
		kal = [[Kal alloc] init];
	}
	return kal;
}

- (Kal16 *)kal16 {
	if (kal16 == nil) {
		kal16 = [[Kal16 alloc] init];
	}
	return kal16;
}

- (Rms *)rms {
	if (rms == nil) {
		rms = [[Rms alloc] init];
	}
	return rms;
}

- (Rms8k *)rms8k {
	if (rms8k == nil) {
		rms8k = [[Rms8k alloc] init];
	}
	return rms8k;
}

- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}

- (Slt8k *)slt8k {
	if (slt8k == nil) {
		slt8k = [[Slt8k alloc] init];
	}
	return slt8k;
}

- (TimeAwb *)timeawb {
	if (timeawb == nil) {
		timeawb = [[TimeAwb alloc] init];
	}
	return timeawb;
}


@end
