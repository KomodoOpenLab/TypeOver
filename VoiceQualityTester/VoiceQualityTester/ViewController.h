//
//  ViewController.h
//  VoiceQualityTester
//
//  Created by Owen McGirr on 30/05/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenEars/FliteController.h>
#import <Slt/Slt.h>
#import <Slt8k/Slt8k.h>
#import <Kal/Kal.h>
#import <Kal16/Kal16.h>
#import <Rms/Rms.h>
#import <Rms8k/Rms8k.h>
#import <Awb/Awb.h>
#import <Awb8k/Awb8k.h>
#import <TimeAwb/TimeAwb.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource> {
	
	
	
	__weak IBOutlet UIPickerView *voicePicker;
	__weak IBOutlet UITextField *textToSay;
	
	
	NSArray *voices;
	float voiceNumber;
	
	
	Slt *slt;
	Slt8k *slt8k;
	Kal *kal;
	Kal16 *kal16;
	Rms *rms;
	Rms8k *rms8k;
	Awb *awb;
	Awb8k *awb8k;
	TimeAwb *timeawb;
	
	FliteController *fliteController;
	
	
}



- (IBAction)sayAct:(id)sender;
- (IBAction)keyboardDone:(id)sender;



@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@property (strong, nonatomic) Slt8k *slt8k;
@property (strong, nonatomic) Kal *kal;
@property (strong, nonatomic) Kal16 *kal16;
@property (strong, nonatomic) Rms *rms;
@property (strong, nonatomic) Rms8k *rms8k;
@property (strong, nonatomic) Awb *awb;
@property (strong, nonatomic) Awb8k *awb8k;
@property (strong, nonatomic) TimeAwb *timeawb;



@end
