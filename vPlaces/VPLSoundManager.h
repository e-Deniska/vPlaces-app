//
//  VPLSoundManager.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const VPLSoundManagerDidFailNotification;

extern NSString * const kVPLSoundManagerErrorKey;


@class MPVolumeView;

@interface VPLSoundManager : NSObject

+(instancetype)sharedManager;

-(void)playSoundAtURL:(NSURL*)soundURL afterDelay:(NSTimeInterval)delay muteOthers:(BOOL)mute;

-(void)stopAllSounds;

@property (nonatomic, strong, readonly) MPVolumeView *volumeView;

@property (nonatomic, assign, getter = isMuted) BOOL muted;

@end
