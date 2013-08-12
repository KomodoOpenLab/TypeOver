//
//  ViewController.m
//  iOS7TTSTest
//
//  Created by Owen McGirr on 12/08/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)speakText:(id)sender {
	
	AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:whatToSpeak.text];
	[utterance setRate:0.4];
	AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
	[synth speakUtterance:utterance];
	
}

@end
