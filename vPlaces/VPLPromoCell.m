//
//  VPLPromoCell.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 28.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLPromoCell.h"

@implementation VPLPromoCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
//    self.layer.masksToBounds = NO;
//    self.layer.shadowOffset = CGSizeZero;
//    self.layer.shadowOpacity = 1.0f;
//    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
//    self.layer.shadowRadius = 5.0f;
    
    self.title.layer.masksToBounds = NO;
    self.title.layer.shadowOffset = CGSizeZero;
    self.title.layer.shadowOpacity = 0.9f;
    self.title.layer.shadowColor = [UIColor blackColor].CGColor;
    self.title.layer.shadowRadius = 3.0f;
    
}

@end
