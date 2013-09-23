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

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


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
        userFreqOffset = [self findFrequencyAtLocationInUnigramFrequencyList];
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
	
	
	// set user added word starting frequency
	NSMutableString *userWordsStartFreqQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS WHERE ID = 200;"];
	
	sqlite3_stmt *stmt;
	result = sqlite3_prepare_v2(dbStockWordPrediction, [userWordsStartFreqQuery UTF8String], -1, &stmt, nil);
	int arr[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // set to 10 just incase
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
			arr[i] = sqlite3_column_int(stmt, 2);
			i++;
        }
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	userAddedWordStartFreq = arr[0];
	
	
	shift = true;
	clearString = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	// make navigation controller black
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	
	// make navigation controller non-translucent
	self.navigationController.navigationBar.translucent = NO;
	
	if (![addWordToDictButton isHidden]) {
		// hide add word to dictionary button
		[addWordToDictButton setHidden:YES];
	}
	
	// dummy view to hide system keyboard
	UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	textView.inputView = dummyView;
	
	[self updateLayout];
	
	[self checkNeededKeys];
	
	[textView becomeFirstResponder]; // activate textview
	
	[textView setFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"font_size"]]];
	
	letters = true;
	wordId = 0;
	[self checkShift];
    [self resetMisc];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		[self updateLayout]; // temporary fix for a layout bug when running iOS 7 on an iPhone
	}
}


#pragma mark - layout

- (void)displayContentViewWithContent:(NSString *)content usingChars:(BOOL)usingchars {
	// disable keys behind content view
	
	[self disableKeys];
	
	
	// declare ui elements
	
	UIView *contentView;
	CustomButton *firstContentButton, *secondContentButton, *thirdContentButton, *forthContentButton, *fifthContentButton, *sixthContentButton, *seventhContentButton, *eighthContentButton, *cancelContentButton;
	
	
	if (usingchars) content = [content stringByReplacingOccurrencesOfString:@" " withString:@""]; // remove spaces
	
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];
	if (usingchars) {
		for (int i = 0; i < [content length]; i++) {
			NSString *ch = [content substringWithRange:NSMakeRange(i, 1)];
			[contentArray addObject:ch];
		}
	}
	else {
		contentArray = [NSMutableArray arrayWithArray:[content componentsSeparatedByString:@" "]];
	}
	
	int keys = [contentArray count];
	
	float viewWidth = self.view.bounds.size.width;
	float keyWidth = viewWidth / keys;
	float keyHeight = (self.view.bounds.size.height-textView.bounds.size.height)/2;
	
	CGRect keyFrame = CGRectMake(0, 0, keyWidth, keyHeight);
	
	CGRect viewFrame = CGRectMake(0, textView.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height-textView.bounds.size.height);
	contentView = [[UIView alloc] initWithFrame:viewFrame];
	contentView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:contentView];
	
	
	// layout keys
	
	if (keys>=2) {
		firstContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[firstContentButton setTitle:[contentArray objectAtIndex:0] forState:UIControlStateNormal];
		
		keyFrame.origin.x = keyFrame.size.width;
		secondContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[secondContentButton setTitle:[contentArray objectAtIndex:1] forState:UIControlStateNormal];
	}
	
	if (keys>=4) {
		keyFrame.origin.x = keyFrame.size.width * 2;
		thirdContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[thirdContentButton setTitle:[contentArray objectAtIndex:2] forState:UIControlStateNormal];
		
		keyFrame.origin.x = keyFrame.size.width * 3;
		forthContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[forthContentButton setTitle:[contentArray objectAtIndex:3] forState:UIControlStateNormal];
	}
	
	if (keys>=5) {
		keyFrame.origin.x = keyFrame.size.width * 4;
		fifthContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[fifthContentButton setTitle:[contentArray objectAtIndex:4] forState:UIControlStateNormal];
	}
	
	if (keys>=8) {
		keyFrame.origin.x = keyFrame.size.width * 5;
		sixthContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[sixthContentButton setTitle:[contentArray objectAtIndex:5] forState:UIControlStateNormal];
		
		keyFrame.origin.x = keyFrame.size.width * 6;
		seventhContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[seventhContentButton setTitle:[contentArray objectAtIndex:6] forState:UIControlStateNormal];
		
		keyFrame.origin.x = keyFrame.size.width * 7;
		eighthContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
		[eighthContentButton setTitle:[contentArray objectAtIndex:7] forState:UIControlStateNormal];
	}
	
	keyFrame.origin.x = 0;
	keyFrame.origin.y = keyFrame.size.height;
	keyFrame.size.width = contentView.bounds.size.width;
	cancelContentButton = [[CustomButton alloc] initWithFrame:keyFrame];
	[cancelContentButton setTitle:@"cancel" forState:UIControlStateNormal];
	
	
	// add actions to keys
	
	[firstContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[secondContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[thirdContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[forthContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[fifthContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[sixthContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[seventhContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[eighthContentButton addTarget:self action:@selector(inputContentFromKey:) forControlEvents:UIControlEventTouchUpInside];
	[cancelContentButton addTarget:self action:@selector(removeContentView:) forControlEvents:UIControlEventTouchUpInside];
	
	
	// add keys to content view
	
	[contentView addSubview:firstContentButton];
	[contentView addSubview:secondContentButton];
	[contentView addSubview:thirdContentButton];
	[contentView addSubview:forthContentButton];
	[contentView addSubview:fifthContentButton];
	[contentView addSubview:sixthContentButton];
	[contentView addSubview:seventhContentButton];
	[contentView addSubview:eighthContentButton];
	[contentView addSubview:cancelContentButton];
}

- (void)updateLayout {
	float viewWidth = self.view.bounds.size.width;
	float keyWidth = viewWidth / 3;
	CGRect keyFrame;
	
	
	// get keys right size
	
	keyFrame = addWordToDictButton.frame;
	keyFrame.size.width = viewWidth;
	addWordToDictButton.frame = keyFrame;
	
	keyFrame = useButton.frame;
	keyFrame.size.width = keyWidth;
	useButton.frame = keyFrame;
	keyFrame = settingsButton.frame;
	keyFrame.size.width = keyWidth;
	settingsButton.frame = keyFrame;
	keyFrame = wordsLettersButton.frame;
	keyFrame.size.width = keyWidth;
	wordsLettersButton.frame = keyFrame;
	
	keyFrame = punct1Button.frame;
	keyFrame.size.width = keyWidth;
	punct1Button.frame = keyFrame;
	keyFrame = abc2Button.frame;
	keyFrame.size.width = keyWidth;
	abc2Button.frame = keyFrame;
	keyFrame = def3Button.frame;
	keyFrame.size.width = keyWidth;
	def3Button.frame = keyFrame;
	
	keyFrame = ghi4Button.frame;
	keyFrame.size.width = keyWidth;
	ghi4Button.frame = keyFrame;
	keyFrame = jkl5Button.frame;
	keyFrame.size.width = keyWidth;
	jkl5Button.frame = keyFrame;
	keyFrame = mno6Button.frame;
	keyFrame.size.width = keyWidth;
	mno6Button.frame = keyFrame;
	
	keyFrame = pqrs7Button.frame;
	keyFrame.size.width = keyWidth;
	pqrs7Button.frame = keyFrame;
	keyFrame = tuv8Button.frame;
	keyFrame.size.width = keyWidth;
	tuv8Button.frame = keyFrame;
	keyFrame = wxyz9Button.frame;
	keyFrame.size.width = keyWidth;
	wxyz9Button.frame = keyFrame;
	
	keyFrame = space0Button.frame;
	keyFrame.size.width = keyWidth;
	space0Button.frame = keyFrame;
	
	keyFrame = shiftButton.frame;
	keyFrame.size.width = keyWidth/2;
	shiftButton.frame = keyFrame;
	
	keyFrame = speakButton.frame;
	keyFrame.size.width = keyWidth/2;
	speakButton.frame = keyFrame;
	
	keyFrame = delButton.frame;
	keyFrame.size.width = keyWidth/2;
	delButton.frame = keyFrame;
	
	keyFrame = clearButton.frame;
	keyFrame.size.width = keyWidth/2;
	clearButton.frame = keyFrame;
	
	
	// position keys
	
	keyFrame = addWordToDictButton.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*6);
	addWordToDictButton.frame = keyFrame;
	
	keyFrame = useButton.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*5);
	useButton.frame = keyFrame;
	keyFrame = punct1Button.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*4);
	punct1Button.frame = keyFrame;
	keyFrame = ghi4Button.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*3);
	ghi4Button.frame = keyFrame;
	keyFrame = pqrs7Button.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*2);
	pqrs7Button.frame = keyFrame;
	keyFrame = shiftButton.frame;
	keyFrame.origin.x = 0;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height);
	shiftButton.frame = keyFrame;
	keyFrame = speakButton.frame;
	keyFrame.origin.x = shiftButton.frame.size.width;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height);
	speakButton.frame = keyFrame;
	
	keyFrame = settingsButton.frame;
	keyFrame.origin.x = keyWidth;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*5);
	settingsButton.frame = keyFrame;
	keyFrame = abc2Button.frame;
	keyFrame.origin.x = keyWidth;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*4);
	abc2Button.frame = keyFrame;
	keyFrame = jkl5Button.frame;
	keyFrame.origin.x = keyWidth;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*3);
	jkl5Button.frame = keyFrame;
	keyFrame = tuv8Button.frame;
	keyFrame.origin.x = keyWidth;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*2);
	tuv8Button.frame = keyFrame;
	keyFrame = space0Button.frame;
	keyFrame.origin.x = keyWidth;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height);
	space0Button.frame = keyFrame;
	
	keyFrame = wordsLettersButton.frame;
	keyFrame.origin.x = keyWidth*2;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*5);
	wordsLettersButton.frame = keyFrame;
	keyFrame = def3Button.frame;
	keyFrame.origin.x = keyWidth*2;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*4);
	def3Button.frame = keyFrame;
	keyFrame = mno6Button.frame;
	keyFrame.origin.x = keyWidth*2;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*3);
	mno6Button.frame = keyFrame;
	keyFrame = wxyz9Button.frame;
	keyFrame.origin.x = keyWidth*2;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height*2);
	wxyz9Button.frame = keyFrame;
	keyFrame = delButton.frame;
	keyFrame.origin.x = keyWidth*2;
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height);
	delButton.frame = keyFrame;
	keyFrame = clearButton.frame;
	keyFrame.origin.x = keyWidth*2+(keyWidth/2);
	keyFrame.origin.y = self.view.frame.size.height-(keyFrame.size.height);
	clearButton.frame = keyFrame;
	
	
	// position textview
	
	CGRect textViewFrame;
	textViewFrame.size.width = viewWidth;
	if (!addWordToDictButton.hidden) {
		textViewFrame.size.height = self.view.bounds.size.height-(keyFrame.size.height*6);
	}
	else {
		textViewFrame.size.height = self.view.bounds.size.height-(keyFrame.size.height*5);
	}
	textViewFrame.origin = CGPointMake(0.0, 0.0);
	textView.frame = textViewFrame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateLayout];
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
			msg.body = textView.text;
			msg.messageComposeDelegate=self;
			[self presentViewController:msg animated:YES completion:nil];
		}
	}
	else if (buttonIndex == 1) { // post to facebook
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *fb = [[SLComposeViewController alloc] init];
            fb = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [fb setInitialText:textView.text];
            [self presentViewController:fb animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 2) { // post to twitter
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tw = [[SLComposeViewController alloc] init];
            tw = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tw setInitialText:textView.text];
            [self presentViewController:tw animated:YES completion:nil];
        }
	}
	else if (buttonIndex == 3) { // copy
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = textView.text;
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

- (int)findFrequencyAtLocationInUnigramFrequencyList
{
    int retval = 0;
    int result;
    int frequencysum = 0;
    sqlite3_stmt *stmt;
    int criticalfrequency;
    int criticallocation;
    int cumulativefrequency;
    int totalwords;
    char *szWord = NULL;
    
	NSMutableString *strQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS ORDER BY FREQUENCY DESC;"];
    
    result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &stmt, nil);
    
    //sum all of the unigram frequencies so we can find the 67-percentile
    totalwords = 0;
    if (SQLITE_OK==result)
    {
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
            frequencysum += sqlite3_column_int(stmt, 2);
            totalwords++;
        }
    }
    
    criticalfrequency = frequencysum * 10 / 100;
    
    cumulativefrequency = 0;
    criticallocation = 0;
    if (SQLITE_OK==sqlite3_reset(stmt))
    {
        while (SQLITE_ROW==sqlite3_step(stmt) && cumulativefrequency<criticalfrequency)
        {
            szWord = (char*)sqlite3_column_text(stmt, 1);
            retval = sqlite3_column_int(stmt, 2);
            cumulativefrequency += retval;
            criticallocation++;
        }
    }
    
    NSLog(@"Stock database stats");
    NSLog(@"Number of words: %d",totalwords);
    NSLog(@"total frequency: %d",frequencysum);
    NSLog(@"10th percentile location: %d",criticallocation);
    NSLog(@"word at 10th percentile: %s",szWord);
    NSLog(@"frequency at 10th percentile: %d",retval);
    
    return(retval);
}

- (NSMutableString*)produceQueryWithContextOnly:(NSString*)context {
    NSUInteger conlen = context.length;
    NSMutableString *str;
    
	NSMutableString *strQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS "];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
        if (0!=conlen) {
            [strQuery appendString:@"WHERE WORD LIKE '"];
            
            str = [NSMutableString stringWithCapacity:30];
            int i = 0;
            while (i<conlen) {
                [str appendString:[context substringWithRange:NSMakeRange(i, 1)]];
                [str appendString:@"%"];
                i++;
            }
            
            // check if word contains an apostrophe and make it sql friendly
            str = [NSMutableString stringWithString:[str stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            
            [strQuery appendString:str];
            [strQuery appendString:@"' "];
        }
	}
	else { //regular prediction
        
		// check if word contains an apostrophe and make it sql friendly
        if (0!=conlen) {
            str = [NSMutableString stringWithString:[context stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            
            [strQuery appendString:@"WHERE WORD LIKE '"];
            [strQuery appendString:str];
            [strQuery appendString:@"%' "];
        }
	}
    
    [strQuery appendString:@"ORDER BY FREQUENCY DESC LIMIT 20;"];
	
	return strQuery;
}

- (NSMutableString*)produceBigramQueryWithContext:(NSString*)context {
    NSUInteger conlen = context.length;
    NSMutableString *str;
	
	NSMutableString *strQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS,BIGRAMDATA "];
    [strQuery appendString:@"WHERE WORDS.ID = BIGRAMDATA.ID2 AND BIGRAMDATA.ID1 = "];
    [strQuery appendFormat:@"%i", wordId];
    [strQuery appendString:@" "];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shorthand_pred"]) {
        if (0!=conlen) {
            [strQuery appendString:@"AND WORDS.WORD LIKE '"];
            
            str = [NSMutableString stringWithCapacity:30];
            int i = 0;
            while (i<context.length) {
                [str appendString:[context substringWithRange:NSMakeRange(i, 1)]];
                [str appendString:@"%"];
                i++;
            }
            
            // check if word contains an apostrophe and make it sql friendly
            str = [NSMutableString stringWithString:[str stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            
            [strQuery appendString:str];
            [strQuery appendString:@"' "];
        }
	}
	else { //regular prediction
		
		// check if word contains an apostrophe and make it sql friendly
		context = [NSMutableString stringWithString:[context stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
		
        if (0!=conlen) {
            [strQuery appendString:@"AND WORDS.WORD LIKE '"];
            [strQuery appendString:context];
            [strQuery appendString:@"%' "];
        }
	}
	
    [strQuery appendString:@"ORDER BY BIGRAMDATA.BIGRAMFREQ DESC LIMIT 20;"];
    
	return strQuery;
}

- (int)findWord:(NSString*)str inSortingArray:(NSArray*)arr
{
    int i;
    BOOL bFound = NO;
    int numitems = arr.count;
    wordInfoStruct *record;
    
    i=0;
    while (i<numitems && !bFound)
    {
        record = [arr objectAtIndex:i];
        if ([str isEqualToString:record.word])
        {
            bFound = YES;
        }
        else
        {
            i++;
        }
    }
    
    
    return(bFound ? i : -1);
}

-(float)calculateScore:(wordInfoStruct*)item withTotalUnigramFreq:(float)fTotalUnigramFreq withTotalBigramFreq:(float)fTotalBigramFreq
{
    float rval;
    float fUnigramProbability=0.0,fBigramProbability=0.0;
    float fUnigramWeight = 0.1;
    
    if (fTotalUnigramFreq>=0.9)
    {
        fUnigramProbability = (float)(item.unigramFreq)/fTotalUnigramFreq;
    }
    
    if (fTotalBigramFreq>=0.9)
    {
        fBigramProbability = (float)(item.bigramFreq)/fTotalUnigramFreq;
    }
    
    rval = fUnigramProbability*fUnigramWeight + fBigramProbability*(1.0-fUnigramWeight);
    
    return(rval);
}

- (NSMutableArray*) predictHelper:(NSString*) strContext
{
    NSMutableString *strStockUnigramQuery;
    NSMutableString *strBigramQuery;
    NSString *strUserUnigramQuery;
    NSMutableArray *sortingarr = [NSMutableArray arrayWithCapacity:60];
    NSMutableArray *resultarr = [NSMutableArray arrayWithCapacity:8];
    sqlite3_stmt *stmt;
    wordInfoStruct *item;
    int i;
    float totalunigramfreq,totalbigramfreq;
	
    bool bigram = (0!=wordId);
	
    // get user's added words
    strUserUnigramQuery = [NSString stringWithString:[self produceQueryWithContextOnly:strContext]];
    NSLog(@"User-word unigram query: %@",strUserUnigramQuery);
	
    int result = sqlite3_prepare_v2(dbUserWordPrediction, [strUserUnigramQuery UTF8String], -1, &stmt, nil);
    
    if (SQLITE_OK==result)
    {
        int prednum = 0;
        while (prednum<20 && SQLITE_ROW==sqlite3_step(stmt))
        {
            wordInfoStruct* item = [[wordInfoStruct alloc] init];
            int freq = (int)sqlite3_column_int(stmt,2);
            char *rowData = (char*)sqlite3_column_text(stmt, 1);
            item.word = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
            item.unigramFreq = freq + userFreqOffset; //add headstart value to unigram frequencies from the user table
            item.bigramFreq = 0;
            //NSLog(@"prediction %d: %@ freq=%d",prednum+1,item.word,item.unigramFreq);
            [sortingarr addObject:item];
            prednum++;
        }
    }
    else
    {
        NSLog(@"Query error number: %d",result);
    }
    
    //get stock unigrams
    strStockUnigramQuery = [NSMutableString stringWithString:[self produceQueryWithContextOnly:strContext]];
    NSLog(@"Stock unigram query: %@",strStockUnigramQuery);
    result = sqlite3_prepare_v2(dbStockWordPrediction, [strStockUnigramQuery UTF8String], -1, &stmt, nil);
    
    if (SQLITE_OK==result)
    {
        int prednum = 0;
        while (prednum<20 && SQLITE_ROW==sqlite3_step(stmt))
        {
            wordInfoStruct* item = [[wordInfoStruct alloc] init];
            int freq = (int)sqlite3_column_int(stmt,2);
            char *rowData = (char*)sqlite3_column_text(stmt, 1);
            item.word = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
            item.unigramFreq = freq;
            item.bigramFreq = 0;
            //NSLog(@"prediction %d: %@ freq=%d",prednum+1,item.word,freq);
            [sortingarr addObject:item];
            prednum++;
        }
    }
    else
    {
        NSLog(@"Query error number: %d",result);
    }
    
    //get bigrams
    if (bigram) {
        strBigramQuery = [NSMutableString stringWithString:[self produceBigramQueryWithContext:strContext]];
        NSLog(@"Bigram query: %@",strBigramQuery);
        result = sqlite3_prepare_v2(dbStockWordPrediction, [strBigramQuery UTF8String], -1, &stmt, nil);
        
        if (SQLITE_OK==result)
        {
            int prednum = 0;
            while (prednum<20 && SQLITE_ROW==sqlite3_step(stmt))
            {
                int freq = (int)sqlite3_column_int(stmt,6); //bigram frequency is in column 6
                char *rowData = (char*)sqlite3_column_text(stmt, 1);
                NSString* str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
                //NSLog(@"prediction %d: %@ freq=%d",prednum+1,str,freq);
                int nSub = [self findWord:str inSortingArray:sortingarr];
                if (nSub==-1) //word not there, add it
                {
                    item = [[wordInfoStruct alloc] init];
                    item.word = str;
                    item.bigramFreq = freq;
                    item.unigramFreq = 0;
                    [sortingarr addObject:item];
                }
                else //word already there, just change its bigram frequency
                {
                    item = [sortingarr objectAtIndex:nSub];
                    item.bigramFreq = freq;
                }
                prednum++;
            }
        }
        else
        {
            NSLog(@"Query error number: %d",result);
        }
    }
    
    i = 0;
    totalunigramfreq = 0.0;
    totalbigramfreq = 0.0;
    while (i<[sortingarr count])
    {
        item = [sortingarr objectAtIndex:i];
        NSLog(@"presort %d: w=%@ uni=%d bi=%d",i+1,item.word,item.unigramFreq,item.bigramFreq);
        totalbigramfreq += (float)item.bigramFreq;
        totalunigramfreq += (float)item.unigramFreq;
        i++;
    }
    
    //jumpdown sort to find the top 8 words in the combined list
    int lochigh;
    float highscore = 0.0;
    float score;
    i = 0;
    wordInfoStruct *temp;
    int j;
    int numitems = [sortingarr count];
    NSLog(@"sorting %d items",numitems);
    if (numitems>1)
    {
        while (i<9 && i<numitems)
        {
            lochigh = i;
            temp = [sortingarr objectAtIndex:i];
            highscore = [self calculateScore:temp withTotalUnigramFreq:totalunigramfreq withTotalBigramFreq:totalbigramfreq];
            for (j=i+1;j<numitems;j++)
            {
                temp = [sortingarr objectAtIndex:j];
                score = [self calculateScore:temp withTotalUnigramFreq:totalunigramfreq withTotalBigramFreq:totalbigramfreq];
                if (score>highscore)
                {
                    highscore = score;
                    lochigh = j;
                }
            }
            
            if (lochigh!=i)
            {
                [sortingarr exchangeObjectAtIndex:lochigh withObjectAtIndex:i];
            }
            i++;
        }
    }
    
    i = 0;
    while (i<9 && i<numitems)
    {
        temp = [sortingarr objectAtIndex:i];
        [resultarr addObject:temp.word];
        NSLog(@"word %d: %@ score:%f",i+1,temp.word,[self calculateScore:temp withTotalUnigramFreq:totalunigramfreq withTotalBigramFreq:totalbigramfreq]);
        i++;
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
	[strQuery appendString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
	[strQuery appendString:word];
	[strQuery appendString:@"';"];
    
	sqlite3_stmt *stmt;
    int result = sqlite3_prepare_v2(dbStockWordPrediction, [strQuery UTF8String], -1, &stmt, nil);
	int arr[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // set to 10 just incase
	NSMutableArray *wordsarr = [[NSMutableArray alloc] init];
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
			arr[i] = sqlite3_column_int(stmt, 0);
			char *rowData = (char*)sqlite3_column_text(stmt, 1);
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
	
	result = sqlite3_prepare_v2(dbUserWordPrediction, [strQuery UTF8String], -1, &stmt, nil);
	NSMutableArray *userwordsarr = [[NSMutableArray alloc] init];
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
			char *rowData = (char*)sqlite3_column_text(stmt, 1);
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
		NSLog(@"not identical case");
	}
	
	// check if word is a number
	BOOL isNumber;
	NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
	NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:orgWord];
	isNumber = [alphaNums isSupersetOfSet:inStringSet];
	
	if (wordId==0 && [addWordToDictButton isHidden] && userwordsarr.count==0 && !isNumber && [[NSUserDefaults standardUserDefaults] boolForKey:@"word_pred"]) {
		// show add word to dictionary button
		[addWordToDictButton setHidden:NO];
		[self updateLayout];
		
		// let user know exactly what will be added
		NSMutableString *buttonText = [NSMutableString stringWithString:@"add \""];
		[buttonText appendString:orgWord];
		[buttonText appendString:@"\" to dictionary"];
		[addWordToDictButton setTitle:buttonText forState:UIControlStateNormal];
	}
}

- (BOOL)isWordDelimiter:(char)ch {
	char acceptableChars[] = " ,.?@#!\t\r\n\"[]{}()<>;/=";
	int i = 0;
	while (acceptableChars[i]!= '\0' && acceptableChars[i]!=ch) i++;
	return(acceptableChars[i]==ch);
}

- (void)updatePredState {
    NSString *text = textView.text;
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
    
    currentWord = [currWord copy];
	
	if (![addWordToDictButton isHidden] && ![currentWord isEqualToString:@""]) {
		// hide add word to dictionary button
		[addWordToDictButton setHidden:YES];
		[self updateLayout];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"word_pred"]) { // if word prediction is on
		[self predict];
	}
	
	[self checkNeededKeys];
}

- (void)predict {
	predResultsArray = [self predictHelper:currentWord];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"auto_pred"] && ![inputTimer isValid] && currentWord.length >= [[NSUserDefaults standardUserDefaults] integerForKey:@"auto_pred_after"] && predResultsArray.count!=0 && !words) {
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

- (void)halveUserAddedWordFreqsIfNeeded {
	// check if criteria is met
	NSMutableString *userWordFreqsQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS WHERE FREQUENCY >= 100;"];
	
	sqlite3_stmt *stmt;
    int matchcount = 0;
	int result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordFreqsQuery UTF8String], -1, &stmt, nil);
	
    if (SQLITE_OK==result)
    {
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
            matchcount++;
        }
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	BOOL criteriaMet;
	criteriaMet = matchcount>=10;
	
	// half frequencies if criteria is met
	if (criteriaMet) {
		NSMutableString *userWordHalfFreqsQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS;"];
		
		result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordHalfFreqsQuery UTF8String], -1, &stmt, nil);
		
		if (SQLITE_OK==result)
		{
			while (SQLITE_ROW==sqlite3_step(stmt))
			{
				int row = sqlite3_column_int(stmt, 0);
				int frequency = sqlite3_column_int(stmt, 2);
				
				char *errMsg = NULL;
				
				NSMutableString *updateStatement = [NSMutableString stringWithString:@"UPDATE WORDS SET FREQUENCY = "];
				if (frequency/2 != 0) [updateStatement appendFormat:@"%i", frequency/2];
				if (frequency/2 == 0) [updateStatement appendFormat:@"%i", 1];
				[updateStatement appendString:@" WHERE ID = "];
				[updateStatement appendFormat:@"%i", row];
				[updateStatement appendString:@";"];
				
				sqlite3_exec(dbUserWordPrediction, [updateStatement UTF8String], NULL, NULL, &errMsg);
				if (SQLITE_OK!=result)
				{
					NSLog(@"Error updating frequency: %s",errMsg);
				}
			}
			NSLog(@"frequencies halved");
		}
		else
		{
			NSLog(@"Query error number: %d",result);
		}
	}
}

- (void)updateFrequencyForUserAddedWord:(NSString *)word {
	// get current frequency
	NSMutableString *userWordsQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
	[userWordsQuery appendString:word];
	[userWordsQuery appendString:@"' ORDER BY FREQUENCY DESC LIMIT 10;"];
	
	sqlite3_stmt *stmt;
	int result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordsQuery UTF8String], -1, &stmt, nil);
	int arr[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // set to 10 just incase
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
			arr[i] = sqlite3_column_int(stmt, 2);
			i++;
        }
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	int frequency = arr[0];
	
	
	// increase frequency by one
	char *errMsg = NULL;
	
	NSMutableString *updateStatement = [NSMutableString stringWithString:@"UPDATE WORDS SET FREQUENCY = "];
	[updateStatement appendFormat:@"%i", frequency+1];
	[updateStatement appendString:@" WHERE WORD LIKE '"];
	[updateStatement appendString:word];
	[updateStatement appendString:@"';"];
	
	sqlite3_exec(dbUserWordPrediction, [updateStatement UTF8String], NULL, NULL, &errMsg);
	if (SQLITE_OK!=result)
	{
		NSLog(@"Error updating frequency: %s",errMsg);
	}
	else {
		NSLog(@"Frequency updated");
	}
	
	
	// check frequency
	result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordsQuery UTF8String], -1, &stmt, nil);
	
    if (SQLITE_OK==result)
    {
		int i = 0;
        while (SQLITE_ROW==sqlite3_step(stmt))
        {
			arr[i] = sqlite3_column_int(stmt, 2);
			i++;
        }
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	frequency = arr[0];
	NSLog(@"New frequency is %i", frequency);
	
	
	[self halveUserAddedWordFreqsIfNeeded];
}

- (BOOL)isUserAddedWord:(NSString *)word {
	NSMutableArray *resultarr = [[NSMutableArray alloc] init];
	NSMutableString *userWordsQuery = [NSMutableString stringWithString:@"SELECT * FROM WORDS WHERE WORD LIKE '"];
	[userWordsQuery appendString:word];
	[userWordsQuery appendString:@"' ORDER BY FREQUENCY DESC LIMIT 10;"];
	
	sqlite3_stmt *stmt;
	int result = sqlite3_prepare_v2(dbUserWordPrediction, [userWordsQuery UTF8String], -1, &stmt, nil);
	
	if (SQLITE_OK==result)
	{
		while (SQLITE_ROW==sqlite3_step(stmt))
		{
			char *rowData = (char*)sqlite3_column_text(stmt, 1);
			NSString *str = [NSString stringWithCString:rowData encoding:NSUTF8StringEncoding];
			[resultarr addObject:str];
		}
	}
	else
	{
		NSLog(@"Query error number: %d",result);
	}
	
	return resultarr.count>0;
}

- (void)wordsLetters {
	if (words) {
		bool isUppercase = false;
		if (![currentWord isEqualToString:@""]) {
			// if word begins with uppercase character
			isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[currentWord characterAtIndex:0]];
		}
		int i = 0;
		[wordsLettersButton setTitle:@"letters" forState:UIControlStateNormal];
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, wordsLettersButton);
		if (predResultsArray.count > i) {
			if (isUppercase) {
				[punct1Button setTitle:[[predResultsArray objectAtIndex:i] capitalizedString] forState:UIControlStateNormal];
			}
			else {
				[punct1Button setTitle:[predResultsArray objectAtIndex:i] forState:UIControlStateNormal];
			}
			i++;
		}
		else {
			[punct1Button setTitle:@"" forState:UIControlStateNormal];
		}
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
		if (predResultsArray.count > i) {
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
	}
	if (letters) {
		[self resetKeys];
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
	[delTimer invalidate];
	
    [predResultsArray removeAllObjects];
	
	if (![addWordToDictButton isHidden]) {
		// hide add word to dictionary button
		[addWordToDictButton setHidden:YES];
		[self updateLayout];
	}
    
	currentWord = [NSMutableString stringWithString:@""];
    previousWord = [NSMutableString stringWithString:@""];
	words = false;
	letters = true;
	
	[self wordsLetters];
	[self checkShift];
	[self resetKeys];
}

- (void)resetKeys {
	letters = true;
	words = false;
	
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
	
	[addWordToDictButton setEnabled:YES];
	[useButton setEnabled:YES];
	[settingsButton setEnabled:YES];
	[punct1Button setEnabled:YES];
	[abc2Button setEnabled:YES];
	[def3Button setEnabled:YES];
	[delButton setEnabled:YES];
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
	
	[self checkNeededKeys];
	
	[inputTimer invalidate];
	[delTimer invalidate];
	
	timesCycled=0;
	
	[self checkShift];
}

- (void)disableKeys {
	[addWordToDictButton setEnabled:NO];
	[useButton setEnabled:NO];
	[settingsButton setEnabled:NO];
	[punct1Button setEnabled:NO];
	[abc2Button setEnabled:NO];
	[def3Button setEnabled:NO];
	[delButton setEnabled:NO];
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

- (void)checkNeededKeys {
	if ([textView.text isEqualToString:@""]) {
		[useButton setEnabled:NO];
		[wordsLettersButton setEnabled:NO];
		[speakButton setEnabled:NO];
		[delButton setEnabled:NO];
		if ([clearString isEqualToString:@""]) [clearButton setEnabled:NO];
	}
	else {
		[useButton setEnabled:YES];
		[wordsLettersButton setEnabled:YES];
		[speakButton setEnabled:YES];
		[delButton setEnabled:YES];
		[clearButton setEnabled:YES];
	}
}


#pragma mark - keypad button actions

- (IBAction)addWordToDictAct:(id)sender {
	[self addWordToDict:previousWord withFreq:1];
	
	// hide add word to dictionary button
	[addWordToDictButton setHidden:YES];
	[self updateLayout];
}

- (IBAction)punct1Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(punct1) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)abc2Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(abc2) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)def3Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(def3) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)ghi4Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(ghi4) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)jkl5Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(jkl5) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)mno6Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(mno6) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)pqrs7Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(pqrs7) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)tuv8Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(tuv8) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)wxyz9Act:(id)sender {
	if (letters) {
		if (![inputTimer isValid]) {
			[self startModeForKey:sender withVoiceOverSelector:@selector(wxyz9) usingChars:YES];
		}
		else {
			[self inputContentFromKey:sender];
		}
	}
	else if (words) {
		[self inputPredictionFromKey:sender];
	}
	[self checkShift];
}

- (IBAction)speakAct:(id)sender {
	// future release
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
		[self startModeForKey:sender withVoiceOverSelector:@selector(space0) usingChars:NO];
	}
	else {
		[self inputContentFromKey:sender];
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

- (IBAction)delAct:(id)sender {
	if (![delTimer isValid] && UIAccessibilityIsVoiceOverRunning()) {
		[self backspace]; // prevents a delay
		delTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:@selector(backspace) userInfo:nil repeats:YES];
		[self disableKeys];
		[delButton setEnabled:YES];
	}
	else if ([delTimer isValid] && UIAccessibilityIsVoiceOverRunning()) {
		[self resetKeys];
	}
	else if (!UIAccessibilityIsVoiceOverRunning()) {
		[self backspace];
	}
}

- (IBAction)clearAct:(id)sender {
    if (![textView.text isEqualToString:@""]) {
        clearString = textView.text; // save text
		clearShift = shift; // save shift state
		wordId=0;
        [textView setText:@""];
        shift = true;
		[self resetMisc];
    }
    else {
        textView.text = clearString; // restore text
		shift = clearShift; // restore shift state
    }
	[self updatePredState];
	[self checkShift];
}


#pragma mark - keypad key methods and functions

- (void)startModeForKey:(UIButton *)key withVoiceOverSelector:(SEL)voSelector usingChars:(BOOL)usingChars {
	if (UIAccessibilityIsVoiceOverRunning()) {
		[key setTitle:[key.titleLabel.text substringToIndex:1] forState:UIControlStateNormal];
		inputTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"scan_rate_float"] target:self selector:voSelector userInfo:nil repeats:YES];
		[self disableKeys];
		[key setEnabled:YES];
	}
	else {
		[self displayContentViewWithContent:key.titleLabel.text usingChars:usingChars];
	}
}

- (void)removeContentView:(UIButton *)key {
	[key.superview removeFromSuperview];
	
	[self resetKeys];
}

- (void)inputContentFromKey:(UIButton *)key {
	NSMutableString *st = [NSMutableString stringWithString:textView.text];
	NSString *content = key.titleLabel.text;
	
	// check if shift is on and make appropriate adjustments to the character
	if (shift&&[content length]==1) {
		content = content.uppercaseString;
	}
	
	BOOL done = NO;
	
	if ([key.titleLabel.text isEqualToString:@"."]||[key.titleLabel.text isEqualToString:@"?"]||[key.titleLabel.text isEqualToString:@"!"]||[key.titleLabel.text isEqualToString:@","]) {
		if (st.length>0) {
			if ([self isWordDelimiter:[textView.text characterAtIndex:[textView.text length] - 1]]) {
				st = [NSMutableString stringWithString:[st substringToIndex:[st length] - 1]];
			}
		}
		[st appendString:key.titleLabel.text];
		
		done = YES;
	}
	
	if ([key.titleLabel.text isEqualToString:@"."]||[key.titleLabel.text isEqualToString:@"?"]||[key.titleLabel.text isEqualToString:@"!"]) {
		wordId = 0;
		[st appendString:@" "];
		shift = true;
		[self resetMisc];
		
		done = YES;
	}
	else if ([key.titleLabel.text isEqualToString:@","]) {
		[st appendString:@" "];
		shift = false;
		[self resetMisc];
		
		done = YES;
	}
		
	if ([key.titleLabel.text isEqualToString:@"space"]) {
		[st appendString:@" "];
		shift = false;
		[self resetMisc];
		
		done = YES;
	}
	else if ([key.titleLabel.text isEqualToString:@"0"]) {
		[st appendString:@"0"];
		shift = false;
		
		done = YES;
	}
	
	if (!done) {
		[st appendString:content];
		shift=false;
	}
	
	[textView setText:st];
	
	[self resetKeys];
	
	[self removeContentView:key];
	
	[self updatePredState];
}

- (void)inputPredictionFromKey:(UIButton *)key {
	if (![key.titleLabel.text isEqualToString:@""]) {
		if (![textView.text isEqualToString:@""]) {
			NSString *st = textView.text;
			NSString *wst = currentWord;
			NSMutableString *final;
			
			st = [st substringToIndex:[st length] - [wst length]];
			final = [NSMutableString stringWithString:st];
			
			if (![textView.text isEqualToString:@""]) {
				[final appendString:key.titleLabel.text];
				[final appendString:@" "];
			}
			else {
				final = [NSMutableString stringWithString:key.titleLabel.text];
				[final appendString:@" "];
			}
			
			[textView setText:final];
			
			if ([self isUserAddedWord:key.titleLabel.text]) {
				[self updateFrequencyForUserAddedWord:key.titleLabel.text];
			}
			
			[self resetMisc];
			[self updatePredState];
		}
	}
}

- (void)punct1 {
	if (timesCycled==2) {
		[self resetKeys];
		return;
	}
	else if (![punct1Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:punct1Button];
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
	else if (![abc2Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:abc2Button];
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
	else if (![def3Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:def3Button];
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
	else if (![ghi4Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:ghi4Button];
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
	else if (![jkl5Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:jkl5Button];
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
	else if (![mno6Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:mno6Button];
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
	else if (![pqrs7Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:pqrs7Button];
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
	else if (![tuv8Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:tuv8Button];
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
	else if (![wxyz9Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:wxyz9Button];
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
	else if (![space0Button accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self inputContentFromKey:space0Button];
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
	if (![delButton accessibilityElementIsFocused]&&UIAccessibilityIsVoiceOverRunning()) {
		[self resetKeys];
		[self updatePredState];
		return;
	}
    
	NSString *st = textView.text;
    if ([st length] > 0) {
        st = [st substringToIndex:[st length] - 1];
        [textView setText:st];
    }
	if ([textView.text isEqual: @""]) {
		clearString = @"";
		shift = true;
		[self resetMisc];
	}
	[self checkShift];
}

@end
