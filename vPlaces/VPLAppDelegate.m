//
//  VPLAppDelegate.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLAppDelegate.h"

#import "VPLPlaceManager.h"
#import "VPLPlace.h"
#import "VPLPlaceInfo+Accessors.h"
#import "VPLPlacesViewController.h"

#warning add iPad version! if needed

@implementation VPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [VPLPlaceInfo resetDownloadProgressInContext:[NSManagedObjectContext sharedContext]];
    [[NSManagedObjectContext sharedContext] save];
    return YES;
}

-(void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
 completionHandler:(void (^)())completionHandler
{
    DLog(@"waking up for background session %@", identifier);
    [VPLPlaceManager manager].sessionCompletion = completionHandler;
}

-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
    NSURL *unpacked = [[VPLPlaceManager manager] unpackPlaceArchiveAtURL:url deleteOriginal:YES];
    DLog(@"unpacked to %@", unpacked);
    if (unpacked)
    {
        [[VPLPlaceManager manager] loadLocalPlaces];
        for (VPLPlace * place in [VPLPlaceManager manager].places)
        {
            if ([place.baseURL.lastPathComponent isEqualToString:unpacked.lastPathComponent])
            {
                UINavigationController *nvc = (UINavigationController*)self.window.rootViewController;
                VPLPlacesViewController *vc = (VPLPlacesViewController *)nvc.topViewController;
                [vc navigateToPlaceWithIdentifier:place.identifier];
                return YES;
            }
        }
    }
    return YES;
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



@end
