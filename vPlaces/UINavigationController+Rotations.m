//
//  UINavigationController+Rotations.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 25.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "UINavigationController+Rotations.h"

@implementation UINavigationController (Rotations)

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
