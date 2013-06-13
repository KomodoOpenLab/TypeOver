//
//  ViewController.m
//  TypeOver
//
//  Created by Owen McGirr on 19/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize fliteController;
@synthesize slt;


- (void)viewDidLoad {
    [super viewDidLoad];
	NSString *databasename = [[NSBundle mainBundle] pathForResource:@"EnWords" ofType:nil];
	int result = sqlite3_open([databasename UTF8String], &dbWordPrediction);
	if (SQLITE_OK!=result)
	{
		NSLog(@"couldn't open database result=%d",result);
	}
	else
	{
		NSLog(@"database successfully opened");
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	letters = true;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shift"]) {
		shift = true;
	}
	[self checkShift];
    [self resetMisc];
}









// other actions

- (IBAction)useAct:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Use what you wrote!" message:@"How do you want to use what you wrote?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Post to Facebook", @"Post to Twitter", @"Copy", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *fb = [[SLComposeViewController alloc] init];
            fb = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [fb setInitialText:textArea.text];
            [self presentViewController:fb animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 2) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tw = [[SLComposeViewController alloc] init];
            tw = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tw setInitialText:textArea.text];
            [self presentViewController:tw animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 3) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = textArea.text;
	}
}





























// other methods

- (void)checkShift {
    if (shift) {
        [shiftButton setTitle:@"shift on" forState:UIControlStateNormal];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shift"];
    }
    else {
        [shiftButton setTitle:@"shift off" forState:UIControlStateNormal];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shift"];
    }
}

- (NSMutableArray*) predictHelper:(NSString*) strContext
{
    NSMutableString *strQuery = [[NSMutableString alloc] init];
    [strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
    [strQuery appendString:strContext];
    [strQuery appendString:@"%' ORDER BY FREQUENCY DESC LIMIT 10;"];
    NSLog(@"Generating predictions with query: %@",strQuery);
    sqlite3_stmt *statement;
    int result = sqlite3_prepare_v2(dbWordPrediction, [strQuery UTF8String], -1, &statement, nil);
    NSMutableArray *resultarr = [NSMutableArray arrayWithCapacity:8];
    if (SQLITE_OK==result)
    {
        int prednum = 0;
        while (prednum<8 && SQLITE_ROW==sqlite3_step(statement))
        {
            char *rowData = (char*)sqlite3_column_text(statement, 1);
            NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
            NSLog(@"prediction %d: %@",prednum+1,str);
            [resultarr addObject:str];
            prednum++;
        }
    }
    else
    {
        NSLog(@"Query error number: %d",result);
    }
    return(resultarr);
}

- (void)predict {
	if ([wordString isEqualToString:@""]) {
		wordString = [NSMutableString stringWithString:add];
	}
	else {
		[wordString appendString:add];
	}
	predResultsArray = [self predictHelper:wordString];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"]) {
		if (![inputTimer isValid]) {
			if (wordString.length >= [[NSUserDefaults standardUserDefaults] integerForKey:@"auto_pred_after"] && predResultsArray.count!=0) {
				words = true;
				letters = false;
				[self wordsLetters];
			}
		}
	}
	add = [NSMutableString stringWithString:@""];
}

- (void)resetMisc {
	[inputTimer invalidate];
    [predResultsArray removeAllObjects];
    wordString = [NSMutableString stringWithString:@""];
    add = [NSMutableString stringWithString:@""];
	words = false;
	letters = true;
	[self wordsLetters];
	[self resetKeys];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"File found and parsing started");
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *errorString = [NSString stringWithFormat:@"Error code %ld", (long)[parseError code]];
    NSLog(@"Error parsing XML: %@", errorString);
    
    
    errorParsing=YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    currentElement = [elementName copy];
    ElementValue = [[NSMutableString alloc] init];
    attribs = [attributeDict copy];
    
    if ([elementName isEqualToString:@"w"]) {
        item = [[NSMutableDictionary alloc] init];
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [ElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"w"]) {
        [predArray addObject:[item copy]];
        if (count<10)
        {
            NSString* strFreq = [attribs objectForKey:@"f"];
            int nFreq = [strFreq intValue];
            NSLog(@"ended word: %@ freq=%d",ElementValue,nFreq);
        }
        count++;
    } else {
        [item setObject:ElementValue forKey:elementName];
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (errorParsing == NO)
    {
        NSLog(@"XML processing done!");
        NSLog(@"Total number of words: %d",count);
    } else {
        NSLog(@"Error occurred during XML processing");
    }
    
}

- (void)resetKeys {
	[punct1Button setTitle:@".,?!'@# 1" forState:UIControlStateNormal];
	[abc2Button setTitle:@"abc 2" forState:UIControlStateNormal];
	[def3Button setTitle:@"def 3" forState:UIControlStateNormal];
	[ghi4Button setTitle:@"ghi 4" forState:UIControlStateNormal];
	[jkl5Button setTitle:@"jkl 5" forState:UIControlStateNormal];
	[mno6Button setTitle:@"mno 6" forState:UIControlStateNormal];
	[pqrs7Button setTitle:@"pqrs 7" forState:UIControlStateNormal];
	[tuv8Button setTitle:@"tuv 8" forState:UIControlStateNormal];
	[wxyz9Button setTitle:@"wxyz 9" forState:UIControlStateNormal];
	[space0Button setTitle:@"space 0" forState:UIControlStateNormal];
	[wordsLettersButton setTitle:@"words" forState:UIControlStateNormal];
	[punct1Button setEnabled:YES];
	[abc2Button setEnabled:YES];
	[def3Button setEnabled:YES];
	[backspaceButton setEnabled:YES];
	[ghi4Button setEnabled:YES];
	[jkl5Button setEnabled:YES];
	[mno6Button setEnabled:YES];
	[clearButton setEnabled:YES];
	[pqrs7Button setEnabled:YES];
	[tuv8Button setEnabled:YES];
	[wxyz9Button setEnabled:YES];
	[speakButton setEnabled:YES];
	[shiftButton setEnabled:YES];
	[space0Button setEnabled:YES];
	[wordsLettersButton setEnabled:YES];
	[inputTimer invalidate];
	timesCycled=0;
}

- (void)disableKeys {
	[punct1Button setEnabled:NO];
	[abc2Button setEnabled:NO];
	[def3Button setEnabled:NO];
	[backspaceButton setEnabled:NO];
	[ghi4Button setEnabled:NO];
	[jkl5Button setEnabled:NO];
	[mno6Button setEnabled:NO];
	[clearButton setEnabled:NO];
	[pqrs7Button setEnabled:NO];
	[tuv8Button setEnabled:NO];
	[wxyz9Button setEnabled:NO];
	[speakButton setEnabled:NO];
	[shiftButton setEnabled:NO];
	[space0Button setEnabled:NO];
	[wordsLettersButton setEnabled:NO];
}

- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
	return fliteController;
}

- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}

























// keypad button actions

- (IBAction)punct1Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[punct1Button setTitle:@"." forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(punct1) userInfo:nil repeats:YES];
			[self disableKeys];
			[punct1Button setEnabled:YES];
		}
		else {
			if ([punct1Button.titleLabel.text isEqualToString:@"."]||[punct1Button.titleLabel.text isEqualToString:@"?"]||[punct1Button.titleLabel.text isEqualToString:@"!"]||[punct1Button.titleLabel.text isEqualToString:@","]) {
				if (space) {
					NSString *st = textArea.text;
					NSString *wst = wordString;
					if ([st length] > 0) {
						st = [st substringToIndex:[st length] - 1];
						[textArea setText:st];
						if ([wst length] > 0) {
							wst = [wst substringToIndex:[wst length] - 1];
							wordString = [NSMutableString stringWithString:wst];
							add = [NSMutableString stringWithString:@""];
						}
					}
				}
			}
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			[st appendString:punct1Button.titleLabel.text];
			if ([punct1Button.titleLabel.text isEqualToString:@"."]||[punct1Button.titleLabel.text isEqualToString:@"?"]||[punct1Button.titleLabel.text isEqualToString:@"!"]) {
				[st appendString:@" "];
				shift = true;
				[self resetMisc];
			}
			else if ([punct1Button.titleLabel.text isEqualToString:@","]) {
				[st appendString:@" "];
				[self resetMisc];
			}
			[textArea setText:st];
			[self resetKeys];
		}
	}
	else if (words) {
		words = false;
		letters = true;
		[self wordsLetters];
	}
	[self checkShift];
}

- (IBAction)abc2Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[abc2Button setTitle:@"a" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(abc2) userInfo:nil repeats:YES];
			[self disableKeys];
			[abc2Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:abc2Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![abc2Button.titleLabel.text isEqualToString:@"2"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![abc2Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:abc2Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:abc2Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)def3Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[def3Button setTitle:@"d" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(def3) userInfo:nil repeats:YES];
			[self disableKeys];
			[def3Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:def3Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![def3Button.titleLabel.text isEqualToString:@"3"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![def3Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:def3Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:def3Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)ghi4Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[ghi4Button setTitle:@"g" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(ghi4) userInfo:nil repeats:YES];
			[self disableKeys];
			[ghi4Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:ghi4Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![ghi4Button.titleLabel.text isEqualToString:@"4"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![ghi4Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:ghi4Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:ghi4Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)jkl5Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[jkl5Button setTitle:@"j" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(jkl5) userInfo:nil repeats:YES];
			[self disableKeys];
			[jkl5Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:jkl5Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![jkl5Button.titleLabel.text isEqualToString:@"5"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![jkl5Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:jkl5Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:jkl5Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)mno6Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[mno6Button setTitle:@"m" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(mno6) userInfo:nil repeats:YES];
			[self disableKeys];
			[mno6Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:mno6Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![mno6Button.titleLabel.text isEqualToString:@"6"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![mno6Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:mno6Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:mno6Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)pqrs7Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[pqrs7Button setTitle:@"p" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(pqrs7) userInfo:nil repeats:YES];
			[self disableKeys];
			[pqrs7Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:pqrs7Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![pqrs7Button.titleLabel.text isEqualToString:@"7"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![pqrs7Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:pqrs7Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:pqrs7Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)tuv8Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[tuv8Button setTitle:@"t" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(tuv8) userInfo:nil repeats:YES];
			[self disableKeys];
			[tuv8Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:tuv8Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![tuv8Button.titleLabel.text isEqualToString:@"8"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![tuv8Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:tuv8Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:tuv8Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)wxyz9Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[wxyz9Button setTitle:@"w" forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(wxyz9) userInfo:nil repeats:YES];
			[self disableKeys];
			[wxyz9Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			add = [NSMutableString stringWithString:wxyz9Button.titleLabel.text];
			if (shift) {
				add = [NSMutableString stringWithString:add.uppercaseString];
			}
			if (shift&&![wxyz9Button.titleLabel.text isEqualToString:@"9"]) {
				[st appendString:add.uppercaseString];
				shift = false;
			}
			else {
				[st appendString:add];
			}
			[textArea setText:st];
			[self resetKeys];
			if (![add isEqualToString:@""]) {
				[self predict];
			}
		}
	}
	else if (words) {
		if (![wxyz9Button.titleLabel.text isEqualToString:@""]) {
			if (![textArea.text isEqualToString:@""]) {
				NSString *st = textArea.text;
				NSString *wst = wordString;
				NSMutableString *final;
				st = [st substringToIndex:[st length] - [wst length]];
				textArea.text = st;
				final = [NSMutableString stringWithString:st];
				if (![textArea.text isEqualToString:@""]) {
					[final appendString:wxyz9Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				else {
					final = [NSMutableString stringWithString:wxyz9Button.titleLabel.text];
					[final appendString:@" "];
					textArea.text = final;
				}
				space=true;
				[self resetMisc];
			}
		}
	}
	[self checkShift];
}

- (IBAction)speakAct:(id)sender {
	[self.fliteController say:textArea.text withVoice:self.slt];
}

- (IBAction)shiftAct:(id)sender {
    if (shift) {
        shift = false;
    }
    else {
        shift = true;
    }
	[self checkShift];
}

- (IBAction)space0Act:(id)sender {
	if (![inputTimer isValid]) {
		[space0Button setTitle:@"space" forState:UIControlStateNormal];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(space0) userInfo:nil repeats:YES];
		[self disableKeys];
		[space0Button setEnabled:YES];
	}
	else {
		NSMutableString *st = [NSMutableString stringWithString:textArea.text];
		if ([space0Button.titleLabel.text isEqualToString:@"space"]) {
			[st appendString:@" "];
			space=true;
			[self resetMisc];
		}
		else {
			[st appendString:@"0"];
		}
		[textArea setText:st];
		[self resetKeys];
	}
	[self checkShift];
}

- (IBAction)wordsLettersAct:(id)sender {
	if (predResultsArray.count!=0) {
		if (words) {
			words = false;
			letters = true;
		}
		else if (letters) {
			words = true;
			letters = false;
		}
		[self wordsLetters];
	}
}

- (IBAction)backspaceAct:(id)sender {
	if ([backspaceTimer isValid]) {
		[backspaceTimer invalidate];
	}
	else {
		backspaceTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(backspace) userInfo:nil repeats:YES];
	}
}

- (IBAction)clearAct:(id)sender {
    if (![textArea.text isEqualToString:@""]) {
        clearString = textArea.text;
        [textArea setText:@""];
        shift = true;
    }
    else {
        textArea.text = clearString;
    }
	space=false;
	[self checkShift];
    [self resetMisc];
}




























// keypad methods

- (void)punct1 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([punct1Button.titleLabel.text isEqualToString:@"."]) {
		[punct1Button setTitle:@"," forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@","]) {
		[punct1Button setTitle:@"?" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"?"]) {
		[punct1Button setTitle:@"!" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"!"]) {
		[punct1Button setTitle:@"'" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"'"]) {
		[punct1Button setTitle:@"@" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"@"]) {
		[punct1Button setTitle:@"#" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"#"]) {
		[punct1Button setTitle:@"1" forState:UIControlStateNormal];
	}
	else if ([punct1Button.titleLabel.text isEqualToString:@"1"]) {
		[punct1Button setTitle:@"." forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)abc2 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([abc2Button.titleLabel.text isEqualToString:@"a"]) {
		[abc2Button setTitle:@"b" forState:UIControlStateNormal];
	}
	else if ([abc2Button.titleLabel.text isEqualToString:@"b"]) {
		[abc2Button setTitle:@"c" forState:UIControlStateNormal];
	}
	else if ([abc2Button.titleLabel.text isEqualToString:@"c"]) {
		[abc2Button setTitle:@"2" forState:UIControlStateNormal];
	}
	else if ([abc2Button.titleLabel.text isEqualToString:@"2"]) {
		[abc2Button setTitle:@"a" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)def3 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([def3Button.titleLabel.text isEqualToString:@"d"]) {
		[def3Button setTitle:@"e" forState:UIControlStateNormal];
	}
	else if ([def3Button.titleLabel.text isEqualToString:@"e"]) {
		[def3Button setTitle:@"f" forState:UIControlStateNormal];
	}
	else if ([def3Button.titleLabel.text isEqualToString:@"f"]) {
		[def3Button setTitle:@"3" forState:UIControlStateNormal];
	}
	else if ([def3Button.titleLabel.text isEqualToString:@"3"]) {
		[def3Button setTitle:@"d" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)ghi4 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([ghi4Button.titleLabel.text isEqualToString:@"g"]) {
		[ghi4Button setTitle:@"h" forState:UIControlStateNormal];
	}
	else if ([ghi4Button.titleLabel.text isEqualToString:@"h"]) {
		[ghi4Button setTitle:@"i" forState:UIControlStateNormal];
	}
	else if ([ghi4Button.titleLabel.text isEqualToString:@"i"]) {
		[ghi4Button setTitle:@"4" forState:UIControlStateNormal];
	}
	else if ([ghi4Button.titleLabel.text isEqualToString:@"4"]) {
		[ghi4Button setTitle:@"g" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)jkl5 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([jkl5Button.titleLabel.text isEqualToString:@"j"]) {
		[jkl5Button setTitle:@"k" forState:UIControlStateNormal];
	}
	else if ([jkl5Button.titleLabel.text isEqualToString:@"k"]) {
		[jkl5Button setTitle:@"l" forState:UIControlStateNormal];
	}
	else if ([jkl5Button.titleLabel.text isEqualToString:@"l"]) {
		[jkl5Button setTitle:@"5" forState:UIControlStateNormal];
	}
	else if ([jkl5Button.titleLabel.text isEqualToString:@"5"]) {
		[jkl5Button setTitle:@"j" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)mno6 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([mno6Button.titleLabel.text isEqualToString:@"m"]) {
		[mno6Button setTitle:@"n" forState:UIControlStateNormal];
	}
	else if ([mno6Button.titleLabel.text isEqualToString:@"n"]) {
		[mno6Button setTitle:@"o" forState:UIControlStateNormal];
	}
	else if ([mno6Button.titleLabel.text isEqualToString:@"o"]) {
		[mno6Button setTitle:@"6" forState:UIControlStateNormal];
	}
	else if ([mno6Button.titleLabel.text isEqualToString:@"6"]) {
		[mno6Button setTitle:@"m" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)pqrs7 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([pqrs7Button.titleLabel.text isEqualToString:@"p"]) {
		[pqrs7Button setTitle:@"q" forState:UIControlStateNormal];
	}
	else if ([pqrs7Button.titleLabel.text isEqualToString:@"q"]) {
		[pqrs7Button setTitle:@"r" forState:UIControlStateNormal];
	}
	else if ([pqrs7Button.titleLabel.text isEqualToString:@"r"]) {
		[pqrs7Button setTitle:@"s" forState:UIControlStateNormal];
	}
	else if ([pqrs7Button.titleLabel.text isEqualToString:@"s"]) {
		[pqrs7Button setTitle:@"7" forState:UIControlStateNormal];
	}
	else if ([pqrs7Button.titleLabel.text isEqualToString:@"7"]) {
		[pqrs7Button setTitle:@"p" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)tuv8 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([tuv8Button.titleLabel.text isEqualToString:@"t"]) {
		[tuv8Button setTitle:@"u" forState:UIControlStateNormal];
	}
	else if ([tuv8Button.titleLabel.text isEqualToString:@"u"]) {
		[tuv8Button setTitle:@"v" forState:UIControlStateNormal];
	}
	else if ([tuv8Button.titleLabel.text isEqualToString:@"v"]) {
		[tuv8Button setTitle:@"8" forState:UIControlStateNormal];
	}
	else if ([tuv8Button.titleLabel.text isEqualToString:@"8"]) {
		[tuv8Button setTitle:@"t" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)wxyz9 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([wxyz9Button.titleLabel.text isEqualToString:@"w"]) {
		[wxyz9Button setTitle:@"x" forState:UIControlStateNormal];
	}
	else if ([wxyz9Button.titleLabel.text isEqualToString:@"x"]) {
		[wxyz9Button setTitle:@"y" forState:UIControlStateNormal];
	}
	else if ([wxyz9Button.titleLabel.text isEqualToString:@"y"]) {
		[wxyz9Button setTitle:@"z" forState:UIControlStateNormal];
	}
	else if ([wxyz9Button.titleLabel.text isEqualToString:@"z"]) {
		[wxyz9Button setTitle:@"9" forState:UIControlStateNormal];
	}
	else if ([wxyz9Button.titleLabel.text isEqualToString:@"9"]) {
		[wxyz9Button setTitle:@"w" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)space0 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	if ([space0Button.titleLabel.text isEqualToString:@"space"]) {
		[space0Button setTitle:@"0" forState:UIControlStateNormal];
	}
	else if ([space0Button.titleLabel.text isEqualToString:@"0"]) {
		[space0Button setTitle:@"space" forState:UIControlStateNormal];
		timesCycled++;
	}
}

- (void)wordsLetters {
	if (words) {
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, punct1Button);
		[punct1Button setTitle:@"" forState:UIControlStateNormal];
		if (predResultsArray.count > 0) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:0];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[abc2Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[abc2Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 1) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:1];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[def3Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[def3Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 2) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:2];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[ghi4Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[ghi4Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 3) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:3];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[jkl5Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[jkl5Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 4) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:4];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[mno6Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[mno6Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 5) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:5];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[pqrs7Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[pqrs7Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 6) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:6];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[tuv8Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[tuv8Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 7) {
			NSString *ws = wordString;
			NSString *ps = [predResultsArray objectAtIndex:7];
			int lngth = [ps length] - [ws length];
			NSMutableString *final = [NSMutableString stringWithString:ws];
			[final appendString:[ps substringFromIndex:[ps length] - lngth]];
			[wxyz9Button setTitle:final forState:UIControlStateNormal];
		}
		else {
			[wxyz9Button setTitle:@"" forState:UIControlStateNormal];
		}
		[wordsLettersButton setTitle:@"letters" forState:UIControlStateNormal];
	}
	if (letters) {
		[punct1Button setTitle:@".,?!'@# 1" forState:UIControlStateNormal];
		[abc2Button setTitle:@"abc 2" forState:UIControlStateNormal];
		[def3Button setTitle:@"def 3" forState:UIControlStateNormal];
		[ghi4Button setTitle:@"ghi 4" forState:UIControlStateNormal];
		[jkl5Button setTitle:@"jkl 5" forState:UIControlStateNormal];
		[mno6Button setTitle:@"mno 6" forState:UIControlStateNormal];
		[pqrs7Button setTitle:@"pqrs 7" forState:UIControlStateNormal];
		[tuv8Button setTitle:@"tuv 8" forState:UIControlStateNormal];
		[wxyz9Button setTitle:@"wxyz 9" forState:UIControlStateNormal];
		[wordsLettersButton setTitle:@"words" forState:UIControlStateNormal];
	}
}

- (void)backspace {
    NSString *st = textArea.text;
    NSString *wst = wordString;
    if ([st length] > 0) {
        st = [st substringToIndex:[st length] - 1];
        [textArea setText:st];
		if ([wst length] > 0) {
			wst = [wst substringToIndex:[wst length] - 1];
			wordString = [NSMutableString stringWithString:wst];
			add = [NSMutableString stringWithString:@""];
		}
        if ([textArea.text isEqual: @""]) {
			shift = true;
			[self checkShift];
			[self resetMisc];
        }
		words = false;
		letters = true;
		space=false;
		[self wordsLetters];
    }
	[self resetKeys];
	[self checkShift];
}
@end
