//
//  SettingsViewController.h
//  TypeOver
//
//  Created by Owen McGirr on 24/03/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController {
	
	
	// outlets
	
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
	__weak IBOutlet UISwitch *textSpeakPredToggleSwitch;
	__weak IBOutlet UIButton *aboutTextSpeakPred;
	__weak IBOutlet UIButton *aboutFontSize;
	
	
	// variables
	
	bool autoPred, manualDwellTime, textSpeak;
	float inputRate;
	int autoPredAfter, selRate, scanRateInd;
	NSTimer *scanRateIndicatorTimer;
	
	
}


// actions 

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
- (IBAction)textSpeakPredToggleAct:(id)sender;
- (IBAction)aboutTextSpeakPredAct:(id)sender;
- (IBAction)aboutFontSizeAct:(id)sender;


@end
