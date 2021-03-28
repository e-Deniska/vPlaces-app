//
//  VPLImage.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPLAnimatedImageView.h"

@interface VPLImage : NSObject

@property (nonatomic, readonly) UIImage *image;

@property (nonatomic, copy, readonly) NSURL *imageURL;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval durationRandomness;

-(void)displayInAnimatedImageView:(VPLAnimatedImageView*)animatedImageView;

-(instancetype)initWithImageURL:(NSURL*)imageURL
                       duration:(NSTimeInterval)duration
                     randomness:(NSTimeInterval)randomness;

+(instancetype)imageWithImageURL:(NSURL*)imageURL
                        duration:(NSTimeInterval)duration
                      randomness:(NSTimeInterval)randomness;

@end
