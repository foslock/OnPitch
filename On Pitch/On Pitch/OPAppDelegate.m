//
//  OPAppDelegate.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPAppDelegate.h"
#import "OPMicInput.h"
#import "OPNoteTranslator.h"
#import "OPNote.h"
#import <DropboxSDK/DropboxSDK.h>
#import "OPSamplePlayer.h"
#import <Crashlytics/Crashlytics.h>

@interface OPAppDelegate () <DBSessionDelegate>

@property (strong, nonatomic) NSString *relinkUserId;

@end

@implementation OPAppDelegate

+ (OPAppDelegate*)currentDelegate {
    return (OPAppDelegate*)[[UIApplication sharedApplication] delegate];
}

+ (NSString*)documentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark - Application Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Connect to Crashlytics API
    [Crashlytics startWithAPIKey:@"2696b6180c803c2901bd36859ff21f19420506cb"];
    
    // Override point for customization after application launch.
    [application setIdleTimerDisabled:YES];
    
    // This initializes the audio handler/input before anything else in the App can touch it.
    [OPMicInput sharedInput];
    
    // Authenticate for Dropbox
    NSString *appKey = @"h3sako7p759hbj9";
    NSString *appSecret = @"i71gyxyr16eeq21";
    NSString *root = kDBRootDropbox; // either kDBRootAppFolder or kDBRootDropbox
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:appKey
                                                   appSecret:appSecret
                                                        root:root];
    dbSession.delegate = self;
    [DBSession setSharedSession:dbSession];

    // Loads all of the samples so no lag time when playing reference track back
    [OPSamplePlayer sharedPlayer];
    
    // Drop the "testmidi1.mid" file into the docs folder for testing
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[OPAppDelegate documentsPath]
                                                                         error:NULL];
    BOOL found = NO;
    for (NSString* path in files) {
        if ([[path lastPathComponent] isEqualToString:@"testmidi1.mid"]) {
            found = YES;
        }
    }
    
    if (!found) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"testmidi1" ofType:@"mid"];
        NSData* data = [NSData dataWithContentsOfFile:path];
        NSString* newPath = [[OPAppDelegate documentsPath] stringByAppendingPathComponent:@"testmidi1.mid"];
        [data writeToFile:newPath atomically:YES];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
	self.relinkUserId = userId;
	[[[UIAlertView alloc] initWithTitle:@"Dropbox Session Ended"
                                 message:@"Do you want to relink?"
                                delegate:self
                       cancelButtonTitle:@"Cancel"
                       otherButtonTitles:@"Relink", nil]
	 show];
}

@end
