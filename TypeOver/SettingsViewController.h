//
//  SettingsViewController.h
//  TypeOver
//
//  Created by Owen McGirr on 24/03/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController {
	
	
#pragma mark - outlets 
	
	__weak IBOutlet UILabel *manualDwellTimeLabel;
	__weak IBOutlet UISwitch *manualDwellTimeToggleSwitch;
    __weak IBOutlet UIButton *dwellTimeDownButton;
    __weak IBOutlet UIButton *dwellTimeUpButton;
	__weak IBOutlet UILabel *dwellTimeLabel;
	__weak IBOutlet UISwitch *autoPredToggleSwitch;
	__weak IBOutlet UILabel *autoPredAfterLabel;
	__weak IBOutlet UIButton *autoPredAfterDownButton;
    __weak IBOutlet UIButton *fontSizeUpButton;
	__weak IBOutlet UIButton *fontSizeDownButton;
    __weak IBOutlet UIButton *autoPredAfterUpButton;
	__weak IBOutlet UIButton *aboutDwellTimeButton;
	__weak IBOutlet UIButton *aboutAutoPredButton;
	__weak IBOutlet UIButton *aboutAutoPredAfterButton;
	__weak IBOutlet UIButton *aboutManualDwellTime;
	__weak IBOutlet UISwitch *shorthandPredToggleSwitch;
	__weak IBOutlet UIButton *aboutShorthandPred;
	__weak IBOutlet UIButton *aboutFontSize;
	
	
#pragma mark - variables 
	
	bool autoPred, manualDwellTime, shorthandPred;
	float inputRate;
	int autoPredAfter, selRate, scanRateInd, fontSize;
	NSTimer *scanRateIndicatorTimer;
	
	
}


#pragma mark - ui actions

- (IBAction)dwellTimeDownAct:(id)sender;
- (IBAction)dwellTimeUpAct:(id)sender;
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


@end
