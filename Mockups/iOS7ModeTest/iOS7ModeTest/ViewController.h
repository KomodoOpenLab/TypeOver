//
//  ViewController.h
//  iOS7ModeTest
//
//  Created by Owen McGirr on 02/09/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomButton.h"

@interface ViewController : UIViewController {
	
	
	__weak IBOutlet UITextField *textView;
	__weak IBOutlet UIButton *abc2Button;
	
	UIView *contentView;
	CustomButton *firstContentButton, *secondContentButton, *thirdContentButton, *forthContentButton, *fifthContentButton, *sixthContentButton, *seventhContentButton, *eighthContentButton, *cancelContentButton;

}


- (IBAction)abc2Act:(id)sender;


@end
