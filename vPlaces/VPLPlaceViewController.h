//
//  VPLPlaceViewController.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPLPlace.h"
#import "DPHue.h"

@interface VPLPlaceViewController : UIViewController

@property (nonatomic, strong) VPLPlace *place;

@property (nonatomic, strong) DPHue *hue;

@end
