//
//  ViewController.h
//  iOS7TTSTest
//
//  Created by Owen McGirr on 12/08/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVSpeechSynthesis.h>

@interface ViewController : UIViewController {
	
	
	// outlets
	
	__weak IBOutlet UITextView *whatToSpeak;
	
	
}


// ui actions

- (IBAction)speakText:(id)sender;


@end
