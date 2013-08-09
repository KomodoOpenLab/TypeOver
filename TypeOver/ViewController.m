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


#pragma mark - view controller methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// load stock word prediction database
	NSString *databasename = [[NSBundle mainBundle] pathForResource:@"EnWords" ofType:nil];
	int result = sqlite3_open([databasename UTF8String], &dbStockWordPrediction);
	if (SQLITE_OK!=result)
	{
		NSLog(@"couldn't open stock database result=%d",result);
	}
	else
	{
		NSLog(@"stock database successfully opened");
	}
	
	// load or create user word prediction database
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *dbFile = [documentsPath stringByAppendingPathComponent:@"UserWords"];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:dbFile];
	if (fileExists) {
		result = sqlite3_open([dbFile UTF8String], &dbUserWordPrediction);
		if (SQLITE_OK!=result)
		{
			NSLog(@"couldn't open user database result=%d",result);
		}
		else
		{
			NSLog(@"user database successfully opened");
		}
	}
	else {
		BOOL bSuccess = YES;
		result = sqlite3_open([dbFile UTF8String], &dbUserWordPrediction);
		if (SQLITE_OK!=result)
		{
			NSLog(@"couldn't create user database result=%d",result);
			bSuccess = NO;
		}
		if (bSuccess) {
			char *errMsg = NULL;
			const char *createSQL = "CREATE TABLE WORDS(ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, FREQUENCY INTEGER);";
			result = sqlite3_exec(dbUserWordPrediction, createSQL, NULL, NULL, &errMsg);
			if (SQLITE_OK!=result)
			{
				NSLog(@"Error creating WORDS table: %s",errMsg);
				bSuccess = NO;
			}
			createSQL = "CREATE INDEX WORDS_IDX ON WORDS (FREQUENCY DESC, WORD);";
			result = sqlite3_exec(dbUserWordPrediction, createSQL, NULL, NULL, &errMsg);
			if (SQLITE_OK!=result)
			{
				NSLog(@"Error creating index on WORDS table: %s",errMsg);
				bSuccess = NO;
			}
		}
	}
	
	shift = true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	// hide add word to dictionary button
	[addWordToDictButton setHidden:YES];
	CGRect frame = textArea.frame;
	frame.size.height = frame.size.height+addWordToDictButton.frame.size.height+8;
	textArea.frame = frame;
	
	// dummy view to hide system keyboard
	UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
	textArea.inputView = dummyView;
	
	[textArea becomeFirstResponder]; // activate textarea
	
	letters = true;
	[textArea setFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"font_size"]]];
	wordId = 0;
	[self checkShift];
    [self resetMisc];
}


#pragma mark - use button methods

- (IBAction)useAct:(id)sender {
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"Use what you wrote!" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send as Message", @"Post to Facebook", @"Post to Twitter", @"Copy", nil];
    [actions showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) { // send as message
		if ([MFMessageComposeViewController canSendText]) {
			MFMessageComposeViewController *msg = [[MFMessageComposeViewController alloc] init];
			msg.body = textArea.text;
			msg.messageComposeDelegate=self;
			[self presentViewController:msg animated:YES completion:nil];
		}
	}
	else if (buttonIndex == 1) { // post to facebook
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *fb = [[SLComposeViewController alloc] init];
            fb = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [fb setInitialText:textArea.text];
            [self presentViewController:fb animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 2) { // post to twitter
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tw = [[SLComposeViewController alloc] init];
            tw = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tw setInitialText:textArea.text];
            [self presentViewController:tw animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 3) { // copy
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = textArea.text;
		NSLog(@"copied");
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)msg didFinishWithResult:(MessageComposeResult)result {
	switch (result)
	{
		case MessageComposeResultCancelled:
			NSLog(@"Result: cancelled");
			break;
		case MessageComposeResultSent:
			NSLog(@"Result: sent");
			break;
		case MessageComposeResultFailed:
			NSLog(@"Result: failed");
			break;
		default:
			NSLog(@"Result: not sent");
			break;
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
}


#pragma mark - word prediction

- (NSMutableArray*) predictHelper:(NSString*) strContext
{
    NSMutableString *strQuery = [[NSMutableString alloc] init];
    NSMutableArray *resultarr = [NSMutableArray arrayWithCapacity:8];
	
	if (![strContext isEqualToString:@""]) {
		bool bigram;
		if (wordId == 0) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
				NSLog(@"shorthand prediction");
				[strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
				NSMutableString *str = [[NSMutableString alloc] init];
				int i = 0;
				while (i<strContext.length) {
					[str appendString:[strContext substringWithRange:NSMakeRange(i, 1)]];
					[str appendString:@"%"];
					i++;
				}
				
				// check if word contains an apostrophe and make it sql friendly
				str = [NSMutableString stringWithString:[str stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				
				[strQuery appendString:str];
				[strQuery appendString:@"' ORDER BY FREQUENCY DESC LIMIT 10;"];
			}
			else {
				NSLog(@"normal prediction");
				
				// check if word contains an apostrophe and make it sql friendly
				strContext = [NSMutableString stringWithString:[strContext stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				
				[strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
				[strQuery appendString:strContext];
				[strQuery appendString:@"%' ORDER BY FREQUENCY DESC LIMIT 10;"];
			}
			bigram=false;
		}
		else {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
				NSLog(@"shorthand prediction");
				[strQuery appendString:@"SELECT * FROM WORDS, BIGRAMDATA WHERE WORDS.ID = BIGRAMDATA.ID2 AND BIGRAMDATA.ID1 = "];
				[strQuery appendFormat:@"%i", wordId];
				[strQuery appendString:@" AND WORDS.WORD LIKE '"];
				NSMutableString *str = [[NSMutableString alloc] init];
				int i = 0;
				while (i<strContext.length) {
					[str appendString:[strContext substringWithRange:NSMakeRange(i, 1)]];
					[str appendString:@"%"];
					i++;
				}
				
				// check if word contains an apostrophe and make it sql friendly
				str = [NSMutableString stringWithString:[str stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				
				[strQuery appendString:str];
				[strQuery appendString:@"' ORDER BY BIGRAMDATA.BIGRAMFREQ DESC LIMIT 10;"];
			}
			else {
				NSLog(@"normal prediction");
				
				// check if word contains an apostrophe and make it sql friendly
				strContext = [NSMutableString stringWithString:[strContext stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				
				[strQuery appendString:@"SELECT * FROM WORDS, BIGRAMDATA WHERE WORDS.ID = BIGRAMDATA.ID2 AND BIGRAMDATA.ID1 = "];
				[strQuery appendFormat:@"%i", wordId];
				[strQuery appendString:@" AND WORDS.WORD LIKE '"];
				[strQuery appendString:strContext];
				[strQuery appendString:@"%' ORDER BY BIGRAMDATA.BIGRAMFREQ DESC LIMIT 10;"];
			}
			bigram=true;
		}
		NSLog(@"Generating predictions with query: %@",strQuery);
		
		sqlite3_stmt *statement;
		
		// get user's added words
		NSMutableString *userWordsQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
			NSLog(@"shorthand prediction");
			[strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
			NSMutableString *str = [[NSMutableString alloc] init];
			int i = 0;
			while (i<strContext.length) {
				[str appendString:[strContext substringWithRange:NSMakeRange(i, 1)]];
				[str appendString:@"%"];
				i++;
			}
			[userWordsQuery appendString:str];
		}
		else {
			[userWordsQuery appendString:strContext];
			[userWordsQuery appendString:@"%"];
		}
		[userWordsQuery appendString:@"' ORDER BY FREQUENCY DESC LIMIT 10;"];
		
		int result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordsQuery UTF8String], -1, &statement, nil);
		
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
		
		result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &statement, nil);
		
		if (resultarr.count<8) {
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
		}
		
		if (resultarr.count<8&&bigram) { // bigram results didn't fill array
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
				[strQuery setString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
				NSMutableString *str = [[NSMutableString alloc] init];
				
				// check if word contains an apostrophe and make it single again
				strContext = [NSMutableString stringWithString:[strContext stringByReplacingOccurrencesOfString:@"''" withString:@"'"]];
				
				int i = 0;
				while (i<wordString.length) {
					[str appendString:[strContext substringWithRange:NSMakeRange(i, 1)]];
					[str appendString:@"%"];
					i++;
				}
				
				// check if word contains an apostrophe and make it sql friendly
				str = [NSMutableString stringWithString:[str stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				
				[strQuery appendString:str];
				[strQuery appendString:@"' ORDER BY FREQUENCY DESC LIMIT 10;"];
			}
			else {
				[strQuery setString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
				
				// apostrophes should already be sql friendly at this point
				
				[strQuery appendString:strContext];
				[strQuery appendString:@"%' ORDER BY FREQUENCY DESC LIMIT 10;"];
			}
			
			result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &statement, nil);
			
			if (SQLITE_OK==result)
			{
				int prednum = resultarr.count;
				int remaining = 8-resultarr.count;
				int count = 0;
				while (count<remaining && SQLITE_ROW==sqlite3_step(statement))
				{
					char *rowData = (char*)sqlite3_column_text(statement, 1);
					NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
					if (![resultarr containsObject:str]) {
						NSLog(@"prediction %d: %@",prednum+1,str);
						[resultarr addObject:str];
						prednum++;
						count++;
					}
				}
			}
			else
			{
				NSLog(@"Query error number: %d",result);
			}
		}
	}
	else {
		[strQuery appendString:@"SELECT * FROM WORDS, BIGRAMDATA WHERE WORDS.ID = BIGRAMDATA.ID2 AND BIGRAMDATA.ID1 = "];
		[strQuery appendFormat:@"%i", wordId];
		[strQuery appendString:@" ORDER BY BIGRAMDATA.BIGRAMFREQ DESC LIMIT 10;"];
		NSLog(@"Generating predictions with query: %@",strQuery);
		
		sqlite3_stmt *statement;
		int result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &statement, nil);
		
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
		
		if (resultarr.count<8) { // bigram results didn't fill array
			[strQuery setString:@"SELECT * FROM WORDS"];
			[strQuery appendString:@" ORDER BY FREQUENCY DESC LIMIT 10;"];
		}
		
		result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &statement, nil);
		
		if (SQLITE_OK==result)
		{
			int prednum = resultarr.count;
			int remaining = 8-resultarr.count;
			int count = 0;
			while (count<remaining && SQLITE_ROW==sqlite3_step(statement))
			{
				char *rowData = (char*)sqlite3_column_text(statement, 1);
				NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
				if (![resultarr containsObject:str]) { // if word wasn't in bigram
					NSLog(@"prediction %d: %@",prednum+1,str);
					[resultarr addObject:str];
					prednum++;
					count++;
				}
			}
		}
		else
		{
			NSLog(@"Query error number: %d",result);
		}
	}
	
    return(resultarr);
}

- (void)getWordId:(NSString *)word {
	NSLog(@"getting id for word: %@", word);
	
	// original word
	NSString *orgWord = word;
	
	// check if word contains an apostrophe and make it sql friendly
	word = [word stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
	NSMutableString *strQuery = [[NSMutableString alloc] init];
	[strQuery appendString:@"SELECT * FROM WORDS WHERE WORDS.WORD LIKE '"];
	[strQuery appendString:word];
	[strQuery appendString:@"';"];
    
	sqlite3_stmt *statement;
    int result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &statement, nil);
	int arr[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // set to 10 just incase
	NSMutableArray *wordsarr = [[NSMutableArray alloc] init];
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(statement))
        {
			arr[i] = sqlite3_column_int(statement, 0);
			char *rowData = (char*)sqlite3_column_text(statement, 1);
			NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
			[wordsarr addObject:str];
			i++;
        }
		NSLog(@"amount of stock results: %i", i);
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	result = sqlite3_prepare_v2(dbUserWordPrediction, [strQuery UTF8String], -1, &statement, nil);
	NSMutableArray *userwordsarr = [[NSMutableArray alloc] init];
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(statement))
        {
			char *rowData = (char*)sqlite3_column_text(statement, 1);
			NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
			[userwordsarr addObject:str];
			i++;
        }
		NSLog(@"amount of user results: %i", i);
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	if (arr[1]!=0) { // more than 1 result
		wordId = arr[[wordsarr indexOfObject:orgWord]]; // case sensitive
		NSLog(@"identical case");
	}
	else {
		wordId = arr[0]; // non case sensitive
		NSLog(@"lowercase");
	}
	
	if (wordId==0 && [addWordToDictButton isHidden] && userwordsarr.count==0) {
		// show add word to dictionary button
		[addWordToDictButton setHidden:NO];
		CGRect frame = textArea.frame;
		frame.size.height = frame.size.height-addWordToDictButton.frame.size.height-8;
		textArea.frame = frame;
	}
}

- (BOOL)isWordDelimiter:(char)ch {
	char acceptableChars[] = " ,.!@#!\t\r\n\"[]{}()<>;/=";
	int i = 0;
	while (acceptableChars[i]!= '\0' && acceptableChars[i]!=ch) i++;
	return(acceptableChars[i]==ch);
}

- (void)updatePredState {
    NSString *text = textArea.text;
    NSString *currWord = @"", *prevWord = @"", *wordDelimiter = @"";
    int len = text.length;
    int i;
    int tokenstart,tokenlen;
    
    if (len>0)
    {
        //start on the last character of the line
        i = len - 1;
        
        //get the current partially typed word
        
        //tokenstart is at the rightmost character of the word
        tokenstart = i;
        
        //move to the left until a word delimiter or the beginning of the string
        while (i>=0 && ![self isWordDelimiter:[text characterAtIndex:i]])
            i--;
        
        //get the length
        tokenlen = tokenstart - i;
        
        if (tokenlen!=0)
        {
            //get the substring (calculate the start of the word by subtracting the length from the end of the word)
            currWord = [text substringWithRange:NSMakeRange(tokenstart-tokenlen+1, tokenlen)];
        }
        
        //now search for the word delimiter
        tokenstart = i;
        
        //move to the left until a *non* word delimiter or the beginning of the string
        while (i>=0 && [self isWordDelimiter:[text characterAtIndex:i]])
            i--;
        
        //get the length
        tokenlen = tokenstart - i;
        
        if (tokenlen!=0)
        {
            //get the substring (calculate the start of the word by subtracting the length from the end of the word)
            wordDelimiter = [text substringWithRange:NSMakeRange(tokenstart-tokenlen+1, tokenlen)];
        }
        
        //finally, get the previous word
        tokenstart = i;
        
        //move to the left until a word delimiter or the beginning of the string
        while (i>=0 && ![self isWordDelimiter:[text characterAtIndex:i]])
            i--;
        
        //get the length
        tokenlen = tokenstart - i;
        
        if (tokenlen!=0)
        {
            //get the substring (calculate the start of the word by subtracting the length from the end of the word)
            prevWord = [text substringWithRange:NSMakeRange(tokenstart-tokenlen+1, tokenlen)];
        }
    }
	
	previousWord = prevWord;
    
    NSLog(@"prevWord=\"%@\" wordDelimiter=\"%@\" currWord=\"%@\"",prevWord,wordDelimiter,currWord);
    
    if (0!=prevWord.length && 0!=wordDelimiter.length && [wordDelimiter isEqualToString:@" "])
    {
        [self getWordId:prevWord]; //this function should return an id instead of setting a member variable
    }
    else
    {
        wordId = 0; //0 isn't a valid id
    }
    
    wordString = [currWord copy];
    [self predict];
}

- (void)predict {
	predResultsArray = [self predictHelper:wordString];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"] && ![inputTimer isValid] && wordString.length >= [[NSUserDefaults standardUserDefaults] integerForKey:@"auto_pred_after"] && predResultsArray.count!=0 && !words) {
		words = true;
		letters = false;
		[self wordsLetters];
	}
}

- (void)addWordToDict:(NSString *)wordstr withFreq:(int)freq
{
    BOOL bSuccess = YES;
    char* ins = "INSERT INTO WORDS (WORD, FREQUENCY) VALUES(?, ?);";
    
    sqlite3_stmt *stmt;
	
    if (sqlite3_prepare_v2(dbUserWordPrediction,ins,-1,&stmt,nil)!=SQLITE_OK)
    {
        NSLog(@"failed to prepare");
        bSuccess = NO;
    }
	
    if(bSuccess)
    {
        sqlite3_bind_text(stmt, 1, [wordstr UTF8String], -1, NULL);
        sqlite3_bind_int(stmt, 2, freq);
        if (SQLITE_DONE!=sqlite3_step(stmt))
        {
            NSLog(@"failed to step");
            bSuccess = NO;
        }
    }
    
    sqlite3_finalize(stmt);
}

- (void)wordsLetters {
	if (words) {
		bool isUppercase = false;
		if (![wordString isEqualToString:@""]) {
			isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[wordString characterAtIndex:0]];
		}
		int i = 0;
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, punct1Button);
		[punct1Button setTitle:@"" forState:UIControlStateNormal];
		if (predResultsArray.count > 0) {
			if (isUppercase) {
				[abc2Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[abc2Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[abc2Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 1) {
			if (isUppercase) {
				[def3Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[def3Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[def3Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 2) {
			if (isUppercase) {
				[ghi4Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[ghi4Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[ghi4Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 3) {
			if (isUppercase) {
				[jkl5Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[jkl5Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[jkl5Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 4) {
			if (isUppercase) {
				[mno6Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[mno6Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[mno6Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 5) {
			if (isUppercase) {
				[pqrs7Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[pqrs7Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[pqrs7Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 6) {
			if (isUppercase) {
				[tuv8Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[tuv8Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[tuv8Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > 7) {
			if (isUppercase) {
				[wxyz9Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[wxyz9Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
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


#pragma mark - keypad misc

- (void)checkShift {
    if (shift) {
        [shiftButton setTitle:@"shift on" forState:UIControlStateNormal];
    }
    else {
        [shiftButton setTitle:@"shift off" forState:UIControlStateNormal];
    }
}

- (void)resetMisc {
	[inputTimer invalidate];
    [predResultsArray removeAllObjects];
	if (![addWordToDictButton isHidden]) {
		// hide add word to dictionary button
		[addWordToDictButton setHidden:YES];
		CGRect frame = textArea.frame;
		frame.size.height = frame.size.height+addWordToDictButton.frame.size.height+8;
		textArea.frame = frame;
	}
    wordString = [NSMutableString stringWithString:@""];
    previousWord = [NSMutableString stringWithString:@""];
	words = false;
	letters = true;
	[self wordsLetters];
	[self resetKeys];
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


#pragma mark - keypad button actions

- (IBAction)addWordToDictAct:(id)sender {
	[self addWordToDict:previousWord withFreq:1];
	// hide add word to dictionary button
	[addWordToDictButton setHidden:YES];
	CGRect frame = textArea.frame;
	frame.size.height = frame.size.height+addWordToDictButton.frame.size.height+8;
	textArea.frame = frame;
}

- (IBAction)punct1Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[punct1Button setTitle:@"." forState:UIControlStateNormal];
			inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(punct1) userInfo:nil repeats:YES];
			[self disableKeys];
			[punct1Button setEnabled:YES];
		}
		else {
			NSMutableString *st = [NSMutableString stringWithString:textArea.text];
			if ([punct1Button.titleLabel.text isEqualToString:@"."]||[punct1Button.titleLabel.text isEqualToString:@"?"]||[punct1Button.titleLabel.text isEqualToString:@"!"]||[punct1Button.titleLabel.text isEqualToString:@","]) {
				if (st.length>0) {
					if ([self isWordDelimiter:[textArea.text characterAtIndex:[textArea.text length] - 1]]) {
						st = [NSMutableString stringWithString:[st substringToIndex:[st length] - 1]];
					}
				}
				[st appendString:punct1Button.titleLabel.text];
			}
			if ([punct1Button.titleLabel.text isEqualToString:@"."]||[punct1Button.titleLabel.text isEqualToString:@"?"]||[punct1Button.titleLabel.text isEqualToString:@"!"]) {
				wordId = 0;
				[st appendString:@" "];
				shift = true;
				[self resetMisc];
			}
			else if ([punct1Button.titleLabel.text isEqualToString:@","]) {
				[st appendString:@" "];
				[self resetMisc];
			}
			else {
				[st appendString:punct1Button.titleLabel.text];
			}
			[textArea setText:st];
			[self resetKeys];
			[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
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
				[self updatePredState];
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
				[self resetMisc];
				[self updatePredState];
			}
		}
	}
	[self checkShift];
}

- (IBAction)speakAct:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming soon!"
													message:@"This feature is still under development."
												   delegate:nil
										  cancelButtonTitle:@"Dismiss"
										  otherButtonTitles: nil];
    [alert show];
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
			[self resetMisc];
		}
		else {
			[st appendString:@"0"];
		}
		[textArea setText:st];
		[self resetKeys];
		[self updatePredState];
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
			[self updatePredState];
		}
		[self wordsLetters];
	}
}

- (IBAction)backspaceAct:(id)sender {
	if ([backspaceTimer isValid]) {
		[backspaceTimer invalidate];
		[self resetKeys];
		[self updatePredState];
	}
	else if (![textArea.text isEqualToString:@""]) {
		[self backspace]; // prevents a delay
		backspaceTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(backspace) userInfo:nil repeats:YES];
		[self disableKeys];
		[backspaceButton setEnabled:YES];
	}
}

- (IBAction)clearAct:(id)sender {
    if (![textArea.text isEqualToString:@""]) {
        clearString = textArea.text; // save text
		clearShift = shift; // save shift state
		wordId=0;
        [textArea setText:@""];
        shift = true;
		[self resetMisc];
    }
    else {
        textArea.text = clearString; // restore text
		shift = clearShift; // restore shift state
    }
	[self updatePredState];
	[self checkShift];
}


#pragma mark - keypad key methods

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
		words = false;
		letters = true;
		[self wordsLetters];
    }
	if ([textArea.text isEqual: @""]) {
		[backspaceTimer invalidate];
		shift = true;
		[self checkShift];
		[self resetKeys];
		[self resetMisc];
	}
	[self checkShift];
}

@end
