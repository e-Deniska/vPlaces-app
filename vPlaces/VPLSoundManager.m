//
//  VPLSoundManager.m
//  vPlaces
//
//  Created by Denis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer;

NSString * const VPLSoundManagerDidFailNotification = @"VPLSoundManagerDidFailNotification";

NSString * const kVPLSoundManagerErrorKey = @"VPLSoundManagerErrorKey";

#import "VPLSoundManager.h"

@interface VPLSoundManager() <AVAudioPlayerDelegate>

@property (nonatomic, strong) NSMutableSet *players;

@property (nonatomic, strong) NSMutableSet *exclusiveSoundURLs;

@property (nonatomic, strong, readwrite) MPVolumeView *volumeView;

@end

@implementation VPLSoundManager

-(id)init
{
    self = [super init];
    if (self)
    {
        self.players = [NSMutableSet set];
        self.exclusiveSoundURLs = [NSMutableSet set];
        self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

+(instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static VPLSoundManager *_sharedManager;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[VPLSoundManager alloc] init];
    });
    return _sharedManager;
}

-(void)stopAllSounds
{
    for (AVAudioPlayer *player in self.players)
    {
        [player stop];
    }
    [self.players removeAllObjects];
}

-(void)playSoundAtURL:(NSURL *)soundURL afterDelay:(NSTimeInterval)delay muteOthers:(BOOL)mute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError * __autoreleasing error;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
        if (error)
        {
            DLog(@"problems initializing player = %@", error);
        }
        player.volume = self.muted ? 0.0f : 1.0f;
        player.delegate = self;
        [self.exclusiveSoundURLs addObject:soundURL];
        
        if ((!player) || (error))
        {
            NSDictionary *userInfo = error ? @{ kVPLSoundManagerErrorKey : error } : nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:VPLSoundManagerDidFailNotification
                                                                object:self
                                                              userInfo:userInfo];
        }
        else
        {
            if (delay)
            {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if (mute)
                    {
                        for (AVAudioPlayer *otherPlayer in self.players)
                        {
                            if (otherPlayer != player)
                            {
                                otherPlayer.volume = self.muted ? 0.0f : 0.1f;
                            }
                        }
                    }
                    [player play];
                });
            }
            else
            {
                if (mute)
                {
                    for (AVAudioPlayer *otherPlayer in self.players)
                    {
                        if (otherPlayer != player)
                        {
                            otherPlayer.volume = self.muted ? 0.0f : 0.1f;
                        }
                    }
                }
                [player play];
            }
            [self.players addObject:player];
        }
    });
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
    if ((flags | AVAudioSessionInterruptionOptionShouldResume) == AVAudioSessionInterruptionOptionShouldResume)
    {
        [player play];
    }
    else
    {
        [self.players removeObject:player];
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if ([self.exclusiveSoundURLs containsObject:player.url])
    {
        for (AVAudioPlayer *player in self.players)
        {
            player.volume = 1.0f;
        }
    }
    [self.players removeObject:player];
}

-(void)setMuted:(BOOL)muted
{
    _muted = muted;
    for (AVAudioPlayer *player in self.players)
    {
        player.volume = muted ? 0.0f : 1.0f;
    }
}

@end
