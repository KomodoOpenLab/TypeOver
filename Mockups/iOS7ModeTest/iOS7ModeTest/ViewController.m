//
//  ViewController.m
//  iOS7ModeTest
//
//  Created by Owen McGirr on 02/09/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	CGRect frame = CGRectMake(0, abc2Button.frame.origin.y, self.view.bounds.size.width, self.view.bounds.size.height-abc2Button.frame.origin.y);
	contentView = [[UIView alloc] initWithFrame:frame];
	contentView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:contentView];
	[contentView setHidden:YES];
	
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)abc2Act:(id)sender {
	CGRect frame;
	frame.size.width = contentView.bounds.size.width/4;
	frame.size.height = contentView.bounds.size.height/2;
	frame.origin = CGPointMake(0, 0);
	
	firstContentButton = [[CustomButton alloc] initWithFrame:frame];
	[firstContentButton setTitle:@"a" forState:UIControlStateNormal];
	
	frame.origin.x = frame.size.width;
	secondContentButton = [[CustomButton alloc] initWithFrame:frame];
	[secondContentButton setTitle:@"b" forState:UIControlStateNormal];
	
	frame.origin.x = frame.size.width * 2;
	thirdContentButton = [[CustomButton alloc] initWithFrame:frame];
	[thirdContentButton setTitle:@"c" forState:UIControlStateNormal];
	
	frame.origin.x = frame.size.width * 3;
	forthContentButton = [[CustomButton alloc] initWithFrame:frame];
	[forthContentButton setTitle:@"2" forState:UIControlStateNormal];
	
	frame.origin.x = 0;
	frame.origin.y = frame.size.height;
	frame.size.width = contentView.bounds.size.width;
	cancelContentButton = [[CustomButton alloc] initWithFrame:frame];
	[cancelContentButton setTitle:@"cancel" forState:UIControlStateNormal];
	
	[firstContentButton addTarget:self action:@selector(inputFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[secondContentButton addTarget:self action:@selector(inputFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[thirdContentButton addTarget:self action:@selector(inputFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[forthContentButton addTarget:self action:@selector(inputFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[cancelContentButton addTarget:self action:@selector(hideContentView) forControlEvents:UIControlEventTouchUpInside];
	
	[contentView addSubview:firstContentButton];
	[contentView addSubview:secondContentButton];
	[contentView addSubview:thirdContentButton];
	[contentView addSubview:forthContentButton];
	[contentView addSubview:cancelContentButton];
	[contentView setHidden:NO];
}

- (void)inputFromKey:(id)sender {
	CustomButton *button = sender;
	
	NSString *add = button.titleLabel.text;
	NSMutableString *text = [NSMutableString stringWithString:textView.text];
	
	[text appendString:add];
	[textView setText:text];
	
	[contentView setHidden:YES];
}

- (void)hideContentView {
	[contentView setHidden:YES];
}

@end
