//
//  ViewController.h
//  TypeOver
//
//  Created by Owen McGirr on 19/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <sqlite3.h>
#import <MessageUI/MessageUI.h>
#import "wordInfoStruct.h"
#import "CustomButton.h"

@interface ViewController : UIViewController <MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    
    
#pragma mark - outlets 
	
    __weak IBOutlet UITextView *textView;
	__weak IBOutlet CustomButton *addWordToDictButton;
    __weak IBOutlet	CustomButton *useButton;
	__weak IBOutlet CustomButton *settingsButton;
    __weak IBOutlet CustomButton *punct1Button;
    __weak IBOutlet CustomButton *abc2Button;
    __weak IBOutlet CustomButton *def3Button;
    __weak IBOutlet CustomButton *ghi4Button;
    __weak IBOutlet CustomButton *jkl5Button;
    __weak IBOutlet CustomButton *mno6Button;
    __weak IBOutlet CustomButton *pqrs7Button;
    __weak IBOutlet CustomButton *tuv8Button;
    __weak IBOutlet CustomButton *wxyz9Button;
    __weak IBOutlet CustomButton *shiftButton;
    __weak IBOutlet CustomButton *wordsLettersButton;
	__weak IBOutlet CustomButton *speakButton;
    __weak IBOutlet CustomButton *space0Button;
    __weak IBOutlet CustomButton *delButton;
    __weak IBOutlet CustomButton *clearButton;
	
	
#pragma mark - ui elements
	
	UIView *contentView;
	CustomButton *firstContentButton, *secondContentButton, *thirdContentButton, *forthContentButton, *fifthContentButton, *sixthContentButton, *seventhContentButton, *eighthContentButton, *cancelContentButton;
    
	
#pragma mark - variables and pointers
    
    NSTimer *inputTimer, *delTimer;
	bool words, letters, shift, clearShift;
    NSString *clearString, *currentWord, *previousWord;
    NSMutableArray *predResultsArray;
    int timesCycled, wordId, userAddedWordStartFreq;
    sqlite3 *dbStockWordPrediction, *dbUserWordPrediction;
    int userFreqOffset;
}


#pragma mark - ui actions 

- (IBAction)useAct:(id)sender;
- (IBAction)addWordToDictAct:(id)sender;
- (IBAction)punct1Act:(id)sender;
- (IBAction)abc2Act:(id)sender;
- (IBAction)def3Act:(id)sender;
- (IBAction)ghi4Act:(id)sender;
- (IBAction)jkl5Act:(id)sender;
- (IBAction)mno6Act:(id)sender;
- (IBAction)pqrs7Act:(id)sender;
- (IBAction)tuv8Act:(id)sender;
- (IBAction)wxyz9Act:(id)sender;
- (IBAction)speakAct:(id)sender;
- (IBAction)shiftAct:(id)sender;
- (IBAction)space0Act:(id)sender;
- (IBAction)wordsLettersAct:(id)sender;
- (IBAction)delAct:(id)sender;
- (IBAction)clearAct:(id)sender;


@end
