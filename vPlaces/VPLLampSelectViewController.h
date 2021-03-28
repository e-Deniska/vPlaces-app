//
//  VPLLampSelectViewController.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPHue.h"

@protocol VPLLampSelectViewControllerDelegate;

@interface VPLLampSelectViewController : UITableViewController

@property (nonatomic, strong) DPHue *hue;

@property (nonatomic, weak) id<VPLLampSelectViewControllerDelegate> delegate;

@end

@protocol VPLLampSelectViewControllerDelegate <NSObject>

-(void)lampSelectViewControllerDidSave:(VPLLampSelectViewController*)sender;

@end
