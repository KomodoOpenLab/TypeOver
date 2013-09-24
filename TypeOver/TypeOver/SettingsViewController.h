//
//  SettingsViewController.h
//  TypeOver
//
//  Created by Owen McGirr on 24/03/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomButton.h"
#import "CustomToggleSwitch.h"

@interface SettingsViewController : UIViewController {
	
	
#pragma mark - outlets 
	
	__weak IBOutlet UILabel *manualDwellTimeLabel;
	__weak IBOutlet CustomToggleSwitch *manualDwellTimeToggleSwitch;
    __weak IBOutlet CustomButton *dwellTimeDownButton;
    __weak IBOutlet CustomButton *dwellTimeUpButton;
	__weak IBOutlet UILabel *dwellTimeLabel;
	__weak IBOutlet CustomToggleSwitch *wordPredToggleSwitch;
	__weak IBOutlet CustomToggleSwitch *autoPredToggleSwitch;
	__weak IBOutlet UILabel *autoPredAfterLabel;
	__weak IBOutlet CustomButton *autoPredAfterDownButton;
    __weak IBOutlet CustomButton *fontSizeUpButton;
	__weak IBOutlet CustomButton *fontSizeDownButton;
    __weak IBOutlet CustomButton *autoPredAfterUpButton;
	__weak IBOutlet CustomButton *aboutDwellTimeButton;
	__weak IBOutlet CustomButton *aboutAutoPredButton;
	__weak IBOutlet CustomButton *aboutAutoPredAfterButton;
	__weak IBOutlet CustomButton *aboutManualDwellTime;
	__weak IBOutlet CustomToggleSwitch *shorthandPredToggleSwitch;
	__weak IBOutlet CustomButton *aboutShorthandPred;
	__weak IBOutlet CustomButton *aboutFontSize;
	__weak IBOutlet CustomButton *aboutWordPred;
	__weak IBOutlet UILabel *autoPredLabel;
	__weak IBOutlet UILabel *shorthandPredLabel;
	
	
#pragma mark - variables 
	
	bool autoPred, manualDwellTime, shorthandPred, wordPred;
	float inputRate;
	int autoPredAfter, selRate, scanRateInd, fontSize;
	NSTimer *scanRateIndicatorTimer;
	
	
}


#pragma mark - ui actions

- (IBAction)dwellTimeDownAct:(id)sender;
- (IBAction)dwellTimeUpAct:(id)sender;
- (IBAction)wordPredToggleAct:(id)sender;
- (IBAction)autoPredictToggleAct:(id)sender;
- (IBAction)autoPredAfterDownAct:(id)sender;
- (IBAction)autoPredAfterUpAct:(id)sender;
- (IBAction)fontSizeDownAct:(id)sender;
- (IBAction)fontSizeUpAct:(id)sender;
- (IBAction)aboutDwellTimeAct:(id)sender;
- (IBAction)aboutAutoPredAct:(id)sender;
- (IBAction)aboutPredAfterAct:(id)sender;
- (IBAction)manualDwellTimeToggleAct:(id)sender;
- (IBAction)aboutManualDwellTimeAct:(id)sender;
- (IBAction)shorthandPredToggleAct:(id)sender;
- (IBAction)aboutShorthandPredAct:(id)sender;
- (IBAction)aboutFontSizeAct:(id)sender;
- (IBAction)aboutWordPredAct:(id)sender;


@end
