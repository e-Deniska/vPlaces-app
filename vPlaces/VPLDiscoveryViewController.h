//
//  VPLDiscoveryViewController.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPHue.h"

@protocol VPLDiscoveryViewControllerDelegate;

@interface VPLDiscoveryViewController : UIViewController

@property (nonatomic, weak) id<VPLDiscoveryViewControllerDelegate> delegate;

@end

@protocol VPLDiscoveryViewControllerDelegate <NSObject>

-(void)discoveryViewController:(VPLDiscoveryViewController*)sender
               didConnectToHue:(DPHue*)hue;

-(void)discoveryViewControllerDidFail:(VPLDiscoveryViewController*)sender;
-(void)discoveryViewControllerDidCancel:(VPLDiscoveryViewController*)sender;

@end
