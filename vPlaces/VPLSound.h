//
//  VPLSound.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VPLSound : NSObject

@property (nonatomic, copy, readonly) NSURL *soundURL;

@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) NSTimeInterval durationOverlap;

@property (nonatomic, assign, readonly) NSTimeInterval startDelay;

@property (nonatomic, assign, readonly) BOOL playSimultaneously;

@property (nonatomic, assign, readonly) BOOL muteOtherSounds;

-(void)play; // takes startDelay into consideration

-(instancetype)initWithSoundURL:(NSURL*)soundURL
                durationOverlap:(NSTimeInterval)durationOverlap
                     startDelay:(NSTimeInterval)startDelay
             playSimultaneously:(BOOL)playSimultaneously
                muteOtherSounds:(BOOL)muteOtherSounds;

+(instancetype)soundWithSoundURL:(NSURL*)soundURL
                 durationOverlap:(NSTimeInterval)durationOverlap
                      startDelay:(NSTimeInterval)startDelay
              playSimultaneously:(BOOL)playSimultaneously
                 muteOtherSounds:(BOOL)muteOtherSounds;


@end
