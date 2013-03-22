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
        char* errMsg = NULL;
        NSLog(@"database successfully opened");
        const char *createSQL = "CREATE TABLE WORDS(ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, FREQUENCY INTEGER);";
        result = sqlite3_exec(dbWordPrediction, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating WORDS table: %s",errMsg);
        }
        
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
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, abc2Button); // VO curser moves to abc2
    inputRate = 4.0;
    selectionRate = inputRate / 100;
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

- (IBAction)speedDownAct:(id)sender {
    inputRate = inputRate + 0.5;
    selectionRate = inputRate / 100;
}

- (IBAction)speedUpAct:(id)sender {
    if (inputRate > 0.5) {
        inputRate = inputRate - 0.5;
        selectionRate = inputRate / 100;
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
    NSMutableArray *resultarr = [NSMutableArray arrayWithCapacity:5];
    if (SQLITE_OK==result)
    {
        int prednum = 0;
        while (prednum<5 && SQLITE_ROW==sqlite3_step(statement))
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
	[predArray removeAllObjects];
    NSString *words = [[NSBundle mainBundle] pathForResource:@"en_wordlist" ofType:@"xml"];
    NSString *URL = words;
    NSString *agentString = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:URL]];
    [request setValue:agentString forHTTPHeaderField:@"User-Agent"];
    NSData* xmlFile = [ NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil ];
    
    
    predArray = [[NSMutableArray alloc] init];
    errorParsing=NO;
    count = 0;
    
    rssParser = [[NSXMLParser alloc] initWithData:xmlFile];
    
    // You may need to turn some of these on depending on the type of XML file you are parsing
    [rssParser setShouldProcessNamespaces:NO];
    [rssParser setShouldReportNamespacePrefixes:NO];
    [rssParser setShouldResolveExternalEntities:NO];
	[rssParser setDelegate:self];
    [rssParser parse];
    NSString *st = @"SELF BEGINSWITH[cd] '";
    st = [st stringByAppendingString:[NSString stringWithFormat:@"%@", wordString]];
    st = [st stringByAppendingString:@"'"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@", st]];
    [predResultsArray removeAllObjects];
    predResultsArray = [[predArray filteredArrayUsingPredicate:predicate] mutableCopy];
    if (predResultsArray.count > 0) {
        [predictionButton setTitle:[NSString stringWithFormat:@"%@", [predResultsArray objectAtIndex:0]] forState:UIControlStateNormal];
    }
    else {
        [predictionButton setTitle:@"" forState:UIControlStateNormal];
    }
    add = [NSMutableString stringWithString:@""];
}

- (void)reset {
    [predictionButton setTitle:@"" forState:UIControlStateNormal];
    [predResultsArray removeAllObjects];
    wordString = [NSMutableString stringWithString:@""];
    add = [NSMutableString stringWithString:@""];
    pred = false;
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
        add = [NSMutableString stringWithString:@"2"];
        [st appendString:@"2"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    a = false;
    b = false;
    c = false;
    two = false;
    [abc2Button setTitle:@"abc 2" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"3"];
        [st appendString:@"3"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    d = false;
    e = false;
    f = false;
    three = false;
    [def3Button setTitle:@"def 3" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"4"];
        [st appendString:@"4"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    g = false;
    h = false;
    i = false;
    four = false;
    [ghi4Button setTitle:@"ghi 4" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"5"];
        [st appendString:@"5"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    j = false;
    k = false;
    l = false;
    five = false;
    [jkl5Button setTitle:@"jkl 5" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"6"];
        [st appendString:@"6"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    m = false;
    n = false;
    o = false;
    six = false;
    [mno6Button setTitle:@"mno 6" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"7"];
        [st appendString:@"7"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    p = false;
    q = false;
    r = false;
    s = false;
    seven = false;
    [pqrs7Button setTitle:@"pqrs 7" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"8"];
        [st appendString:@"8"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    t = false;
    u = false;
    v = false;
    eight = false;
    [tuv8Button setTitle:@"tuv 8" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"9"];
        [st appendString:@"9"];
        [textArea setText:st];
        shift = false;
    }
    if (![add isEqualToString:@""]) {
        [self predict];
    }
    w = false;
    x = false;
    y = false;
    z = false;
    nine = false;
    [wxyz9Button setTitle:@"wxyz 9" forState:UIControlStateNormal];
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
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
        add = [NSMutableString stringWithString:@"0"];
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

- (void)prediction {
    if (pred) {
        if (![textArea.text isEqualToString:@""]) {
            NSString *st = textArea.text;
            NSString *wst = wordString;
            NSMutableString *final;
            st = [st substringToIndex:[st length] - [wst length]];
            textArea.text = st;
            final = [NSMutableString stringWithString:st];
            if (![textArea.text isEqualToString:@""]) {
                [final appendString:predictionButton.titleLabel.text];
                [final appendString:@" "];
                textArea.text = final;
            }
            else {
                final = [NSMutableString stringWithString:predictionButton.titleLabel.text];
                [final appendString:@" "];
                textArea.text = final;
            }
            [self reset];
        }
    }
    [predictionButton setBackgroundImage:[UIImage imageNamed:@"normalButton.png"] forState:UIControlStateNormal];
    secondWord = false;
    thirdWord = false;
    fourthWord = false;
    noWord = false;
    [selectionProgressView setProgress:0.0];
    [selectionTimer invalidate];
}










// keypad button actions

- (IBAction)punct1Act:(id)sender {
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        fs = true;
        cma = false;
        qm = false;
        excl = false;
        apos = false;
        one = false;
        [punct1Button setTitle:@"." forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(punct1) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)abc2Act:(id)sender {
    [self punct1];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        a = true;
        b = false;
        c = false;
        two = false;
        [abc2Button setTitle:@"a" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(abc2) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)def3Act:(id)sender {
    [self punct1];
    [self abc2];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        d = true;
        e = false;
        f = false;
        three = false;
        [def3Button setTitle:@"d" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(def3) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)ghi4Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        g = true;
        h = false;
        i = false;
        four = false;
        [ghi4Button setTitle:@"g" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(ghi4) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)jkl5Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        j = true;
        k = false;
        l = false;
        five = false;
        [jkl5Button setTitle:@"j" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(jkl5) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)mno6Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        m = true;
        n = false;
        o = false;
        six = false;
        [mno6Button setTitle:@"m" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(mno6) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)pqrs7Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self tuv8];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        p = true;
        q = false;
        r = false;
        s = false;
        seven = false;
        [pqrs7Button setTitle:@"p" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(pqrs7) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)tuv8Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self wxyz9];
    [self space0];
	[self prediction];
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
        t = true;
        u = false;
        v = false;
        eight = false;
        [tuv8Button setTitle:@"t" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(tuv8) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)wxyz9Act:(id)sender {
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self space0];
	[self prediction];
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
        w = true;
        x = false;
        y = false;
        z = false;
        nine = false;
        [wxyz9Button setTitle:@"w" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(wxyz9) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
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
    [self punct1];
    [self abc2];
    [self def3];
    [self ghi4];
    [self jkl5];
    [self mno6];
    [self pqrs7];
    [self tuv8];
    [self wxyz9];
	[self prediction];
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
        space = true;
        zero = false;
        [space0Button setTitle:@"space" forState:UIControlStateNormal];
    }
    [selectionProgressView setProgress:0.0];
    [inputTimer invalidate];
    [selectionTimer invalidate];
    inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(space0) userInfo:nil repeats:NO];
    selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
}

- (IBAction)predictionAct:(id)sender {
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
    if (predResultsArray.count > 0) {
        if (secondWord == false && thirdWord == false && fourthWord == false && noWord == false) {
            [predictionButton setTitle:[predResultsArray objectAtIndex:0] forState:UIControlStateNormal];
            secondWord = true;
            thirdWord = false;
            fourthWord = false;
            noWord = false;
            pred = true;
        }
        else if (secondWord) {
			if (predResultsArray.count >= 2) {
				[predictionButton setTitle:[predResultsArray objectAtIndex:1] forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = true;
				fourthWord = false;
				noWord = false;
				pred = true;
			}
			else {
				[predictionButton setTitle:@"" forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = false;
				fourthWord = false;
				noWord = false;
				pred = false;
			}
        }
        else if (thirdWord) {
			if (predResultsArray.count >= 3) {
				[predictionButton setTitle:[predResultsArray objectAtIndex:2] forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = false;
				fourthWord = true;
				noWord = false;
				pred = true;
			}
			else {
				[predictionButton setTitle:@"" forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = false;
				fourthWord = false;
				noWord = false;
				pred = false;
			}
        }
        else if (fourthWord) {
			if (predResultsArray.count >= 4) {
				[predictionButton setTitle:[predResultsArray objectAtIndex:3] forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = false;
				fourthWord = false;
				noWord = true;
				pred = true;
			}
			else {
				[predictionButton setTitle:@"" forState:UIControlStateNormal];
				secondWord = false;
				thirdWord = false;
				fourthWord = false;
				noWord = false;
				pred = false;
			}
        }
        else if (noWord) {
            [predictionButton setTitle:@"" forState:UIControlStateNormal];
            secondWord = false;
            thirdWord = false;
            fourthWord = false;
            noWord = false;
            pred = false;
        }
        [predictionButton setBackgroundImage:[UIImage imageNamed:@"predictionButtonHighlighted.png"] forState:UIControlStateNormal];
        [inputTimer invalidate];
        [selectionTimer invalidate];
        inputTimer = [NSTimer scheduledTimerWithTimeInterval:inputRate target:self selector:@selector(prediction) userInfo:nil repeats:NO];
        selectionTimer = [NSTimer scheduledTimerWithTimeInterval:selectionRate target:self selector:@selector(prog) userInfo:nil repeats:YES];
    }
}

- (IBAction)backspaceAct:(id)sender {
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
	[self prediction];
    NSString *st = textArea.text;
    NSString *wst = wordString;
    if ([st length] > 0) {
        st = [st substringToIndex:[st length] - 1];
        [textArea setText:st];
        if ([textArea.text isEqual: @""]) {
            shift = true;
            [predictionButton setTitle:@"" forState:UIControlStateNormal];
            wordString = [NSMutableString stringWithString:@""];
            add = [NSMutableString stringWithString:@""];
        }
    }
    if ([wst length] > 0) {
        wst = [wst substringToIndex:[wst length] - 1];
        wordString = [NSMutableString stringWithString:wst];
        add = [NSMutableString stringWithString:@""];
        [self predict];
    }
}

- (IBAction)clearAct:(id)sender {
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
	[self prediction];
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
