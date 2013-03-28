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
    [repeatTimer invalidate];
    repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(repeat) userInfo:nil repeats:YES];
	autoPred=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"];
    inputRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"in_rate"];
    selectionRate = inputRate / 100;
	letters = true;
    shift = true;
    [self reset];
}









// other actions

- (IBAction)useAct:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
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

- (void)prog {
    if (selectionProgressView.progress < 1.0) {
        [selectionProgressView setProgress:selectionProgressView.progress + 0.01 animated:YES];
    }
}

- (void)repeat {
    if (shift) {
        [shiftButton setTitle:@"shift on" forState:UIControlStateNormal];
    }
    else {
        [shiftButton setTitle:@"shift off" forState:UIControlStateNormal];
    }
	if (autoPred!=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"]) {
		autoPred=[[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"];
	}
	if (inputRate!=[[NSUserDefaults standardUserDefaults] floatForKey:@"in_rate"]) {
		inputRate=[[NSUserDefaults standardUserDefaults] floatForKey:@"in_rate"];
		selectionRate = inputRate / 100;
	}
	if (autoPredAfter!=[[NSUserDefaults standardUserDefaults] integerForKey:@"autopred_after"]) {
		autoPredAfter=[[NSUserDefaults standardUserDefaults] integerForKey:@"autopred_after"];
	}
}

- (NSMutableArray*) predictHelper:(NSString*) strContext
{
    NSMutableString *strQuery = [[NSMutableString alloc] init];
    [strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
    [strQuery appendString:strContext];
    [strQuery appendString:@"%' ORDER BY FREQUENCY DESC;"];
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
	if (autoPred) {
		if (![selectionTimer isValid]) {
			if (wordString.length >= autoPredAfter && predResultsArray.count!=0) {
				words = true;
				letters = false;
				[self wordsLetters];
			}
		}
	}
	add = [NSMutableString stringWithString:@""];
}

- (void)reset {
    [predResultsArray removeAllObjects];
    wordString = [NSMutableString stringWithString:@""];
    add = [NSMutableString stringWithString:@""];
	words = false;
	letters = true;
	[self wordsLetters];
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









// keypad methods

- (void)punct1 {
    if (fs) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@". "];
        [textArea setText:st];
        [self reset];
        shift = true;
    }
    if (cma) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@", "];
        [textArea setText:st];
        [self reset];
        shift = false;
    }
    if (qm) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"? "];
        [textArea setText:st];
        [self reset];
        shift = true;
    }
    if (excl) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"! "];
        [textArea setText:st];
        [self reset];
        shift = true;
    }
    if (apos) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"'"];
        [textArea setText:st];
        shift = false;
    }
    if (one) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"1"];
        [textArea setText:st];
        shift = false;
    }
    fs = false;
    cma = false;
    qm = false;
    excl = false;
    apos = false;
    one = false;
    [punct1Button setTitle:@".,?!' 1" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
}

- (void)abc2 {
    if (a) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"a"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (b) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"b"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (c) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"c"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (two) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"2"];
        [textArea setText:st];
        shift = false;
    }
    a = false;
    b = false;
    c = false;
    two = false;
    [abc2Button setTitle:@"abc 2" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)def3 {
    if (d) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"d"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (e) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"e"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (f) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"f"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (three) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"3"];
        [textArea setText:st];
        shift = false;
    }
    d = false;
    e = false;
    f = false;
    three = false;
    [def3Button setTitle:@"def 3" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)ghi4 {
    if (g) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"g"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (h) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"h"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (i) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"i"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (four) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"4"];
        [textArea setText:st];
        shift = false;
    }
    g = false;
    h = false;
    i = false;
    four = false;
    [ghi4Button setTitle:@"ghi 4" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)jkl5 {
    if (j) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"j"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (k) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"k"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (l) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"l"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (five) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"5"];
        [textArea setText:st];
        shift = false;
    }
    j = false;
    k = false;
    l = false;
    five = false;
    [jkl5Button setTitle:@"jkl 5" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)mno6 {
    if (m) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"m"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (n) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"n"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (o) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"o"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (six) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"6"];
        [textArea setText:st];
        shift = false;
    }
    m = false;
    n = false;
    o = false;
    six = false;
    [mno6Button setTitle:@"mno 6" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)pqrs7 {
    if (p) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"p"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (q) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"q"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (r) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"r"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (s) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"s"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (seven) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"7"];
        [textArea setText:st];
        shift = false;
    }
    p = false;
    q = false;
    r = false;
    s = false;
    seven = false;
    [pqrs7Button setTitle:@"pqrs 7" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)tuv8 {
    if (t) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"t"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (u) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"u"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (v) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"v"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (eight) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"8"];
        [textArea setText:st];
        shift = false;
    }
    t = false;
    u = false;
    v = false;
    eight = false;
    [tuv8Button setTitle:@"tuv 8" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)wxyz9 {
    if (w) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"w"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (x) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"x"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (y) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"y"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (z) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        add = [NSMutableString stringWithString:@"z"];
        if (shift) {
            [st appendString:add.uppercaseString];
            shift = false;
        }
        else {
            [st appendString:add.lowercaseString];
        }
        [textArea setText:st];
    }
    if (nine) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"9"];
        [textArea setText:st];
        shift = false;
    }
    w = false;
    x = false;
    y = false;
    z = false;
    nine = false;
    [wxyz9Button setTitle:@"wxyz 9" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
    if (![add isEqualToString:@""]) {
        [self predict];
    }
}

- (void)space0 {
    if (space) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@" "];
        [textArea setText:st];
        if (![predArray containsObject:wordString]) {
            [predArray addObject:wordString];
        }
        [self reset];
    }
    if (zero) {
        NSMutableString *st = [NSMutableString stringWithString:textArea.text];
        [st appendString:@"0"];
        [textArea setText:st];
        shift = false;
    }
    space = false;
    zero = false;
    [space0Button setTitle:@"space 0" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
}

- (void)wordsLetters {
	if (words) {
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, punct1Button);
		[punct1Button setTitle:@"" forState:UIControlStateNormal];
		if (predResultsArray.count > 0) {
			[abc2Button setTitle:[predResultsArray objectAtIndex:0] forState:UIControlStateNormal];
		}
		else {
			[abc2Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 1) {
			[def3Button setTitle:[predResultsArray objectAtIndex:1] forState:UIControlStateNormal];
		}
		else {
			[def3Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 2) {
			[ghi4Button setTitle:[predResultsArray objectAtIndex:2] forState:UIControlStateNormal];
		}
		else {
			[ghi4Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 3) {
			[jkl5Button setTitle:[predResultsArray objectAtIndex:3] forState:UIControlStateNormal];
		}
		else {
			[jkl5Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 4) {
			[mno6Button setTitle:[predResultsArray objectAtIndex:4] forState:UIControlStateNormal];
		}
		else {
			[mno6Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 5) {
			[pqrs7Button setTitle:[predResultsArray objectAtIndex:5] forState:UIControlStateNormal];
		}
		else {
			[pqrs7Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 6) {
			[tuv8Button setTitle:[predResultsArray objectAtIndex:6] forState:UIControlStateNormal];
		}
		else {
			[tuv8Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 7) {
			[wxyz9Button setTitle:[predResultsArray objectAtIndex:7] forState:UIControlStateNormal];
		}
		else {
			[wxyz9Button setTitle:@"" forState:UIControlStateNormal];
		}
		[wordsLettersButton setTitle:@"letters" forState:UIControlStateNormal];
	}
	if (letters) {
		[punct1Button setTitle:@".,?!' 1" forState:UIControlStateNormal];
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










// keypad button actions

- (IBAction)punct1Act:(id)sender {
	if ([selectionTimer isValid]&&[punct1Button.titleLabel.text isEqualToString:@".,?!' 1"]) {
		return;
	}
	if (letters) {
		if (fs == false && cma == false && qm == false && excl == false && apos == false && one == false) {
			fs = true;
			cma = false;
			qm = false;
			excl = false;
			apos = false;
			one = false;
			[punct1Button setTitle:@"." forState:UIControlStateNormal];
		}
		else if (fs) {
			fs = false;
			cma = true;
			qm = false;
			excl = false;
			apos = false;
			one = false;
			[punct1Button setTitle:@"," forState:UIControlStateNormal];
		}
		else if (cma) {
			fs = false;
			cma = false;
			qm = true;
			excl = false;
			apos = false;
			one = false;
			[punct1Button setTitle:@"?" forState:UIControlStateNormal];
		}
		else if (qm) {
			fs = false;
			cma = false;
			qm = false;
			excl = true;
			apos = false;
			one = false;
			[punct1Button setTitle:@"!" forState:UIControlStateNormal];
		}
		else if (excl) {
			fs = false;
			cma = false;
			qm = false;
			excl = false;
			apos = true;
			one = false;
			[punct1Button setTitle:@"'" forState:UIControlStateNormal];
		}
		else if (apos) {
			fs = false;
			cma = false;
			qm = false;
			excl = false;
			apos = false;
			one = true;
			[punct1Button setTitle:@"1" forState:UIControlStateNormal];
		}
		else if (one) {
			fs = false;
			cma = false;
			qm = false;
			excl = false;
			apos = false;
			one = false;
			[punct1Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(punct1) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
		words = false;
		letters = true;
		[self wordsLetters];
	}
}

- (IBAction)abc2Act:(id)sender {
	if ([selectionTimer isValid]&&[abc2Button.titleLabel.text isEqualToString:@"abc 2"]) {
		return;
	}
	if (letters) {
		if (a == false && b == false && c == false && two == false) {
			a = true;
			b = false;
			c = false;
			two = false;
			[abc2Button setTitle:@"a" forState:UIControlStateNormal];
		}
		else if (a) {
			a = false;
			b = true;
			c = false;
			two = false;
			[abc2Button setTitle:@"b" forState:UIControlStateNormal];
		}
		else if (b) {
			a = false;
			b = false;
			c = true;
			two = false;
			[abc2Button setTitle:@"c" forState:UIControlStateNormal];
		}
		else if (c) {
			a = false;
			b = false;
			c = false;
			two = true;
			[abc2Button setTitle:@"2" forState:UIControlStateNormal];
		}
		else if (two) {
			a = false;
			b = false;
			c = false;
			two = false;
			[abc2Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(abc2) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)def3Act:(id)sender {
	if ([selectionTimer isValid]&&[def3Button.titleLabel.text isEqualToString:@"def 3"]) {
		return;
	}
	if (letters) {
		if (d == false && e == false && f == false && three == false) {
			d = true;
			e = false;
			f = false;
			three = false;
			[def3Button setTitle:@"d" forState:UIControlStateNormal];
		}
		else if (d) {
			d = false;
			e = true;
			f = false;
			three = false;
			[def3Button setTitle:@"e" forState:UIControlStateNormal];
		}
		else if (e) {
			d = false;
			e = false;
			f = true;
			three = false;
			[def3Button setTitle:@"f" forState:UIControlStateNormal];
		}
		else if (f) {
			d = false;
			e = false;
			f = false;
			three = true;
			[def3Button setTitle:@"3" forState:UIControlStateNormal];
		}
		else if (three) {
			d = false;
			e = false;
			f = false;
			three = false;
			[def3Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(def3) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)ghi4Act:(id)sender {
	if ([selectionTimer isValid]&&[ghi4Button.titleLabel.text isEqualToString:@"ghi 4"]) {
		return;
	}
	if (letters) {
		if (g == false && h == false && i == false && four == false) {
			g = true;
			h = false;
			i = false;
			four = false;
			[ghi4Button setTitle:@"g" forState:UIControlStateNormal];
		}
		else if (g) {
			g = false;
			h = true;
			i = false;
			four = false;
			[ghi4Button setTitle:@"h" forState:UIControlStateNormal];
		}
		else if (h) {
			g = false;
			h = false;
			i = true;
			four = false;
			[ghi4Button setTitle:@"i" forState:UIControlStateNormal];
		}
		else if (i) {
			g = false;
			h = false;
			i = false;
			four = true;
			[ghi4Button setTitle:@"4" forState:UIControlStateNormal];
		}
		else if (four) {
			g = false;
			h = false;
			i = false;
			four = false;
			[ghi4Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(ghi4) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)jkl5Act:(id)sender {
	if ([selectionTimer isValid]&&[jkl5Button.titleLabel.text isEqualToString:@"jkl 5"]) {
		return;
	}
	if (letters) {
		if (j == false && k == false && l == false && five == false) {
			j = true;
			k = false;
			l = false;
			five = false;
			[jkl5Button setTitle:@"j" forState:UIControlStateNormal];
		}
		else if (j) {
			j = false;
			k = true;
			l = false;
			five = false;
			[jkl5Button setTitle:@"k" forState:UIControlStateNormal];
		}
		else if (k) {
			j = false;
			k = false;
			l = true;
			five = false;
			[jkl5Button setTitle:@"l" forState:UIControlStateNormal];
		}
		else if (l) {
			j = false;
			k = false;
			l = false;
			five = true;
			[jkl5Button setTitle:@"5" forState:UIControlStateNormal];
		}
		else if (five) {
			j = false;
			k = false;
			l = false;
			five = false;
			[jkl5Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(jkl5) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)mno6Act:(id)sender {
	if ([selectionTimer isValid]&&[mno6Button.titleLabel.text isEqualToString:@"mno 6"]) {
		return;
	}
	if (letters) {
		if (m == false && n == false && o == false && six == false) {
			m = true;
			n = false;
			o = false;
			six = false;
			[mno6Button setTitle:@"m" forState:UIControlStateNormal];
		}
		else if (m) {
			m = false;
			n = true;
			o = false;
			six = false;
			[mno6Button setTitle:@"n" forState:UIControlStateNormal];
		}
		else if (n) {
			m = false;
			n = false;
			o = true;
			six = false;
			[mno6Button setTitle:@"o" forState:UIControlStateNormal];
		}
		else if (o) {
			m = false;
			n = false;
			o = false;
			six = true;
			[mno6Button setTitle:@"6" forState:UIControlStateNormal];
		}
		else if (six) {
			m = false;
			n = false;
			o = false;
			six = false;
			[mno6Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(mno6) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)pqrs7Act:(id)sender {
	if ([selectionTimer isValid]&&[pqrs7Button.titleLabel.text isEqualToString:@"pqrs 7"]) {
		return;
	}
	if (letters) {
		if (p == false && q == false && r == false && s == false && seven == false) {
			p = true;
			q = false;
			r = false;
			s = false;
			seven = false;
			[pqrs7Button setTitle:@"p" forState:UIControlStateNormal];
		}
		else if (p) {
			p = false;
			q = true;
			r = false;
			s = false;
			seven = false;
			[pqrs7Button setTitle:@"q" forState:UIControlStateNormal];
		}
		else if (q) {
			p = false;
			q = false;
			r = true;
			s = false;
			seven = false;
			[pqrs7Button setTitle:@"r" forState:UIControlStateNormal];
		}
		else if (r) {
			p = false;
			q = false;
			r = false;
			s = true;
			seven = false;
			[pqrs7Button setTitle:@"s" forState:UIControlStateNormal];
		}
		else if (s) {
			p = false;
			q = false;
			r = false;
			s = false;
			seven = true;
			[pqrs7Button setTitle:@"7" forState:UIControlStateNormal];
		}
		else if (seven) {
			p = false;
			q = false;
			r = false;
			s = false;
			seven = false;
			[pqrs7Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(pqrs7) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)tuv8Act:(id)sender {
	if ([selectionTimer isValid]&&[tuv8Button.titleLabel.text isEqualToString:@"tuv 8"]) {
		return;
	}
	if (letters) {
		if (t == false && u == false && v == false && eight == false) {
			t = true;
			u = false;
			v = false;
			eight = false;
			[tuv8Button setTitle:@"t" forState:UIControlStateNormal];
		}
		else if (t) {
			t = false;
			u = true;
			v = false;
			eight = false;
			[tuv8Button setTitle:@"u" forState:UIControlStateNormal];
		}
		else if (u) {
			t = false;
			u = false;
			v = true;
			eight = false;
			[tuv8Button setTitle:@"v" forState:UIControlStateNormal];
		}
		else if (v) {
			t = false;
			u = false;
			v = false;
			eight = true;
			[tuv8Button setTitle:@"8" forState:UIControlStateNormal];
		}
		else if (eight) {
			t = false;
			u = false;
			v = false;
			eight = false;
			[tuv8Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(tuv8) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)wxyz9Act:(id)sender {
	if ([selectionTimer isValid]&&[wxyz9Button.titleLabel.text isEqualToString:@"wxyz 9"]) {
		return;
	}
	if (letters) {
		if (w == false && x == false && y == false && z == false && nine == false) {
			w = true;
			x = false;
			y = false;
			z = false;
			nine = false;
			[wxyz9Button setTitle:@"w" forState:UIControlStateNormal];
		}
		else if (w) {
			w = false;
			x = true;
			y = false;
			z = false;
			nine = false;
			[wxyz9Button setTitle:@"x" forState:UIControlStateNormal];
		}
		else if (x) {
			w = false;
			x = false;
			y = true;
			z = false;
			nine = false;
			[wxyz9Button setTitle:@"y" forState:UIControlStateNormal];
		}
		else if (y) {
			w = false;
			x = false;
			y = false;
			z = true;
			nine = false;
			[wxyz9Button setTitle:@"z" forState:UIControlStateNormal];
		}
		else if (z) {
			w = false;
			x = false;
			y = false;
			z = false;
			nine = true;
			[wxyz9Button setTitle:@"9" forState:UIControlStateNormal];
		}
		else if (nine) {
			w = false;
			x = false;
			y = false;
			z = false;
			nine = false;
			[wxyz9Button setTitle:@"" forState:UIControlStateNormal];
		}
		[selectionProgressView setProgress:0.0];
		[inputTimer invalidate];
		[selectionTimer invalidate];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(wxyz9) userInfo:nil repeats:NO];
		selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
	}
	if (words) {
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
				[self reset];
			}
		}
	}
}

- (IBAction)shiftAct:(id)sender {
    if (shift) {
        shift = false;
    }
    else {
        shift = true;
    }
}

- (IBAction)space0Act:(id)sender {
	if ([selectionTimer isValid]&&[space0Button.titleLabel.text isEqualToString:@"space 0"]) {
		return;
	}
    if (space == false && zero == false) {
        space = true;
        zero = false;
        [space0Button setTitle:@"space" forState:UIControlStateNormal];
    }
    else if (space) {
        space = false;
        zero = true;
        [space0Button setTitle:@"0" forState:UIControlStateNormal];
    }
    else if (zero) {
        space = false;
        zero = false;
        [space0Button setTitle:@"" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(space0) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)wordsLettersAct:(id)sender {
	if ([selectionTimer isValid]) {
		return;
	}
	if (predResultsArray.count!=0) {
		if (words) {
			words = false;
			letters = true;
			if (autoPred && wordString.length==autoPredAfter) {
				autoPred=true;
			}
		}
		else if (letters) {
			words = true;
			letters = false;
		}
		[self predict];
		[self wordsLetters];
	}
}

- (IBAction)backspaceAct:(id)sender {
	if ([selectionTimer isValid]) {
		return;
	}
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
			[self reset];
        }
		words = false;
		letters = true;
		[self wordsLetters];
    }
}

- (IBAction)clearAct:(id)sender {
	if ([selectionTimer isValid]) {
		return;
	}
    if (![textArea.text isEqualToString:@""]) {
        clearString = textArea.text;
        [textArea setText:@""];
        shift = true;
    }
    else {
        textArea.text = clearString;
    }
    [self reset];
}
@end
