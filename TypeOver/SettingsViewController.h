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
	
    __weak IBOutlet UIButton *dwellTimeDownButton;
    __weak IBOutlet UIButton *dwellTimeUpButton;
	__weak IBOutlet UISwitch *autoPredToggleSwitch;
	__weak IBOutlet UILabel *autoPredAfterLabel;
	__weak IBOutlet UIButton *autoPredAfterDownButton;
    __weak IBOutlet UIButton *autoPredAfterUpButton;
	__weak IBOutlet UIBarButtonItem *saveButton;
	
	
	// variables
	
	bool autoPred;
	float inputRate;
	int autoPredAfter;
	
	
}


// actions 

- (IBAction)dwellTimeDownAct:(id)sender;
- (IBAction)dwellTimeUpAct:(id)sender;
- (IBAction)autoPredictToggleAct:(id)sender;
- (IBAction)autoPredAfterDownAct:(id)sender;
- (IBAction)autoPredAfterUpAct:(id)sender;
- (IBAction)saveAct:(id)sender;


@end
