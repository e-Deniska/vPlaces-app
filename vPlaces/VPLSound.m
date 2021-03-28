//
//  VPLSound.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import AVFoundation;

#import "VPLSound.h"
#import "VPLSoundManager.h"

@interface VPLSound()

@property (nonatomic, copy, readwrite) NSURL *soundURL;

@property (nonatomic, assign, readwrite) NSTimeInterval durationOverlap;

@property (nonatomic, assign, readwrite) NSTimeInterval startDelay;

@property (nonatomic, assign, readwrite) BOOL playSimultaneously;

@property (nonatomic, assign, readwrite) BOOL muteOtherSounds;

@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@end

@implementation VPLSound

-(void)play
{
    DLog(@"playing at %.2f - %@", self.startDelay, self.soundURL);
    [[VPLSoundManager sharedManager] playSoundAtURL:self.soundURL
                                         afterDelay:self.startDelay
                                         muteOthers:self.muteOtherSounds];
}

+(instancetype)soundWithSoundURL:(NSURL*)soundURL
                 durationOverlap:(NSTimeInterval)durationOverlap
                      startDelay:(NSTimeInterval)startDelay
              playSimultaneously:(BOOL)playSimultaneously
                 muteOtherSounds:(BOOL)muteOtherSounds
{
    return [[self alloc] initWithSoundURL:soundURL
                          durationOverlap:durationOverlap
                               startDelay:startDelay
                       playSimultaneously:playSimultaneously
                          muteOtherSounds:muteOtherSounds];
}


-(instancetype)initWithSoundURL:(NSURL*)soundURL
                durationOverlap:(NSTimeInterval)durationOverlap
                     startDelay:(NSTimeInterval)startDelay
             playSimultaneously:(BOOL)playSimultaneously
                muteOtherSounds:(BOOL)muteOtherSounds
{
    self = [super init];
    if (self)
    {
        self.soundURL = soundURL;
        self.durationOverlap = durationOverlap;
        self.startDelay = startDelay;
        self.playSimultaneously = playSimultaneously;
        self.muteOtherSounds = muteOtherSounds;
        AVAsset *asset = [AVAsset assetWithURL:self.soundURL];
        self.duration = CMTimeGetSeconds(asset.duration);
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<VPLSound url=%@, startDelay=%.2f>", self.soundURL, self.startDelay];
}

@end
