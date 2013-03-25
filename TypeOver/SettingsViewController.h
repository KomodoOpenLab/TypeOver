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
	
    __weak IBOutlet UIButton *speedDownButton;
    __weak IBOutlet UIButton *speedUpButton;
	__weak IBOutlet UISwitch *autoPredToggleSwitch;
	__weak IBOutlet UIButton *settingsDoneButton;
	
	
	// variables
	
	bool autoPred;
	float selectionRate, inputRate;
	
	
}


// actions 

- (IBAction)speedDownAct:(id)sender;
- (IBAction)speedUpAct:(id)sender;
- (IBAction)autoPredictToggle:(id)sender;
- (IBAction)settingsDone:(id)sender;


@end
