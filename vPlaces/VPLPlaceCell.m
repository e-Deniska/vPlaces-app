//
//  VPLPlaceCell.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 13.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import QuartzCore;

#import "VPLPlaceCell.h"


@interface VPLPlaceCell()

@property (nonatomic, weak) IBOutlet UIImageView *selectionMark;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic, assign) BOOL highlightShown;

@end

@implementation VPLPlaceCell

-(void)awakeFromNib
{
    [super awakeFromNib];

    self.layer.masksToBounds = NO;
    self.layer.drawsAsynchronously = YES;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 0.9f;
    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.layer.shadowRadius = 5.0f;
    self.layer.shouldRasterize = NO;
//    self.layer.allowsEdgeAntialiasing = YES;
    
    self.title.layer.masksToBounds = NO;
    self.title.layer.drawsAsynchronously = YES;
    self.title.layer.shadowOffset = CGSizeZero;
    self.title.layer.shadowOpacity = 1.0f;
    self.title.layer.shadowColor = [UIColor blackColor].CGColor;
    self.title.layer.shadowRadius = 3.0f;
    self.title.layer.shouldRasterize = YES;
    self.title.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.details.layer.masksToBounds = NO;
    self.details.layer.drawsAsynchronously = YES;
    self.details.layer.shadowOffset = CGSizeZero;
    self.details.layer.shadowOpacity = 1.0f;
    self.details.layer.shadowColor = [UIColor blackColor].CGColor;
    self.details.layer.shadowRadius = 3.0f;
    self.details.layer.shouldRasterize = YES;
    self.details.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    
    //    [self updateMotionEffects];
}

-(void)updateSelectionIndication
{
//    DLog(@"got selected=%d, highligted=%d, highlightShown=%d", self.selected, self.highlighted, self.highlightShown);
    if ((self.selected) || (self.highlighted))
    {
        if (!self.highlightShown)
        {
            CABasicAnimation *animationColor = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            animationColor.toValue = (__bridge id)([UIColor whiteColor].CGColor);
            animationColor.removedOnCompletion = NO;
            animationColor.fillMode = kCAFillModeForwards;
            animationColor.duration = 0.1f;
            
            [self.layer addAnimation:animationColor forKey:@"shadowAnimations"];
            self.highlightShown = YES;
        }
    }
    else
    {
        if (self.highlightShown)
        {
            CABasicAnimation *animationColor = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            animationColor.toValue = (__bridge id)([UIColor darkGrayColor].CGColor);
            animationColor.removedOnCompletion = NO;
            animationColor.fillMode = kCAFillModeForwards;
            animationColor.duration = 0.1f;
            
            [self.layer addAnimation:animationColor forKey:@"shadowAnimations"];
            self.highlightShown = NO;
        }
    }
}

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateSelectionIndication];
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateSelectionIndication];
}



-(void)prepareForReuse
{
    //    DLog(@"reusing %@", self.magazineTitle.text);
    [super prepareForReuse];
    [self updateSelectionIndication];
    self.selectionMarkHidden = YES;
    self.marked = NO;
    //    [self updateMotionEffects];
}

-(void)setMarked:(BOOL)marked
{
    if (marked != _marked)
    {
        _marked = marked;
        
        self.selectionMark.image = marked ? [UIImage imageNamed:@"markOn"] : [UIImage imageNamed:@"markOff"];
    }
}

-(BOOL)selectionMarkHidden
{
    return self.selectionMark.hidden;
}

-(void)setSelectionMarkHidden:(BOOL)selectionMarkHidden
{
    self.selectionMark.hidden = selectionMarkHidden;
}

@end
