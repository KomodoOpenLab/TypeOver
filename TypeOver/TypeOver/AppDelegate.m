//
//  AppDelegate.m
//  TypeOver
//
//  Created by Owen McGirr on 19/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // if not running for the first time 
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"first_run"]) {
		int i = 2000;
		float f = (int)(i)/1000; // get float in the format '?.?'
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"first_run"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"auto_pred"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"word_pred"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shorthand_pred"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"manual_scan_rate"];
		[[NSUserDefaults standardUserDefaults] setInteger:i forKey:@"scan_rate_int"];
		[[NSUserDefaults standardUserDefaults] setFloat:f forKey:@"scan_rate_float"];
		[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"auto_pred_after"];
		[[NSUserDefaults standardUserDefaults] setInteger:24 forKey:@"font_size"];
	}
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // save settings 
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
