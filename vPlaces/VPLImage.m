//
//  VPLImage.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLImage.h"

@interface VPLImage()

@property (nonatomic, copy, readwrite) NSURL *imageURL;

@property (nonatomic, assign, readwrite) NSTimeInterval duration;
@property (nonatomic, assign, readwrite) NSTimeInterval durationRandomness;

@end

@implementation VPLImage

+(NSCache*)imageCache
{
    static dispatch_once_t onceToken;
    static NSCache *_imageCache;
    dispatch_once(&onceToken, ^{
        _imageCache = [[NSCache alloc] init];
    });
    return _imageCache;
}

-(void)displayInAnimatedImageView:(VPLAnimatedImageView*)animatedImageView
{
    DLog(@"applying %@", self.imageURL);
    [animatedImageView animateImage:self.image duration:(self.duration + self.durationRandomness)];
}

+(instancetype)imageWithImageURL:(NSURL*)imageURL
                        duration:(NSTimeInterval)duration
                      randomness:(NSTimeInterval)randomness
{
    return [[self alloc] initWithImageURL:imageURL duration:duration randomness:randomness];
}

-(instancetype)initWithImageURL:(NSURL*)imageURL
                       duration:(NSTimeInterval)duration
                     randomness:(NSTimeInterval)randomness
{
    self = [super init];
    if (self)
    {
        self.imageURL = imageURL;
        self.duration = duration;
        self.durationRandomness = randomness;
    }
    return self;
}

-(UIImage *)image
{
    UIImage *_image = [[VPLImage imageCache] objectForKey:self.imageURL];
    if (!_image)
    {
        _image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
        [[VPLImage imageCache] setObject:_image forKey:self.imageURL];
    }
    return _image;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<VPLImage: url=%@, duration=%.2f>", self.imageURL, self.duration];
}

@end
