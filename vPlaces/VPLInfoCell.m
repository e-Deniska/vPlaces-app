//
//  VPLInfoCell.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 22.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLInfoCell.h"

@interface VPLInfoCell()

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *downloadView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (nonatomic, assign) BOOL highlightShown;

@end

@implementation VPLInfoCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.layer.masksToBounds = NO;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 0.9f;
    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.layer.shadowRadius = 5.0f;
    self.layer.shouldRasterize = NO;
    
    self.title.layer.masksToBounds = NO;
    self.title.layer.shadowOffset = CGSizeZero;
    self.title.layer.shadowOpacity = 1.0f;
    self.title.layer.shadowColor = [UIColor blackColor].CGColor;
    self.title.layer.shadowRadius = 3.0f;
    self.title.layer.shouldRasterize = YES;
    
    self.details.layer.masksToBounds = NO;
    self.details.layer.shadowOffset = CGSizeZero;
    self.details.layer.shadowOpacity = 1.0f;
    self.details.layer.shadowColor = [UIColor blackColor].CGColor;
    self.details.layer.shadowRadius = 3.0f;
    self.details.layer.shouldRasterize = YES;
    
    
    self.progressLabel.layer.masksToBounds = NO;
    self.progressLabel.layer.shadowOffset = CGSizeZero;
    self.progressLabel.layer.shadowOpacity = 1.0f;
    self.progressLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.progressLabel.layer.shadowRadius = 5.0f;
    self.progressLabel.layer.shouldRasterize = YES;
    
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
    self.progressHidden = YES;
    self.downloadProgress = 0.0f;
    //    [self updateMotionEffects];
}

-(BOOL)progressHidden
{
    return self.downloadView.hidden;
}

-(void)setProgressHidden:(BOOL)progressHidden
{
    self.downloadView.hidden = progressHidden;
    self.progressLabel.hidden = progressHidden;
}

-(float)downloadProgress
{
    return self.downloadView.alpha;
}

-(void)setDownloadProgress:(float)downloadProgress
{
    self.downloadView.alpha = downloadProgress;
    self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)(downloadProgress * 100)];
}

@end
