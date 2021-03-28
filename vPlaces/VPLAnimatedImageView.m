//
//  VPLAnimatedImageView.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 16.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLAnimatedImageView.h"

@interface VPLAnimatedImageView()

@property (nonatomic, weak) UIImageView *displayedImageView;

@end

@implementation VPLAnimatedImageView

#warning Animate image for duration

-(void)animateImage:(UIImage *)image duration:(NSTimeInterval)duration
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.translatesAutoresizingMaskIntoConstraints = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.image = image;
    imageView.opaque = NO;
    imageView.alpha = 0.0f;
    [self addSubview:imageView];
    if (self.displayedImageView)
    {
        UIImageView *oldImageView = self.displayedImageView;
        self.displayedImageView = imageView;
        [UIView animateWithDuration:1.0f
                         animations:^{
                             imageView.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             [oldImageView removeFromSuperview];
                         }];
    }
    else
    {
        imageView.alpha = 1.0f;
        self.displayedImageView = imageView;
    }
}

@end
