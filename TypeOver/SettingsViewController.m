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
    inputRate = [[NSUserDefaults standardUserDefaults] integerForKey:@"in_rate"];
    selectionRate = inputRate / 100;
	autoPred=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"];
	if (autoPred) {
		autoPredToggleSwitch.on=true;
	}
	else {
		autoPredToggleSwitch.on=false;
	}
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
	[[NSUserDefaults standardUserDefaults] setBool:autoPred forKey:@"auto_pred"];
	[[NSUserDefaults standardUserDefaults] setFloat:inputRate forKey:@"in_rate"];
}








// button actions 

- (IBAction)speedDownAct:(id)sender {
    inputRate = inputRate + 0.5;
    selectionRate = inputRate / 100;
}

- (IBAction)speedUpAct:(id)sender {
    if (inputRate > 0.5) {
        inputRate = inputRate - 0.5;
        selectionRate = inputRate / 100;
    }
}

- (IBAction)autoPredictToggle:(id)sender {
	if (autoPredToggleSwitch.on) {
		autoPred=true;
		NSLog(@"auto predict on");
	}
	else {
		autoPred=false;
		NSLog(@"auto predict off");
	}
}

- (IBAction)settingsDone:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}
@end
