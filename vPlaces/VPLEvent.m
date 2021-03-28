//
//  VPLEvent.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer.MPVolumeView;

#import "VPLEvent.h"
#import "DPHueLight.h"
#import "VPLColor.h"
#import "VPLSound.h"
#import "VPLSoundManager.h"

#define kVPLEventWirelessAudioDelay 2.0f

@interface VPLEvent()

@property (nonatomic, copy, readwrite) NSArray *colors; // of VPLColor's
@property (nonatomic, copy, readwrite) NSArray *sounds; // of VPLSound's
@property (nonatomic, assign, readwrite) NSTimeInterval averageInterval;
@property (nonatomic, assign, readwrite) NSTimeInterval intervalRandomness;

@property (nonatomic, strong) NSArray *lamps;
@property (nonatomic, strong) NSTimer *soundTimer;
@property (nonatomic, strong) NSTimer *colorTimer;
@property (nonatomic, assign) int currentSound;
@property (nonatomic, assign) int currentColor;
@property (nonatomic, assign) int currentLamp;

@property (nonatomic, copy) VPLEventColorsCompletedHanlder colorsCompletion;

@end

@implementation VPLEvent

+(instancetype)eventWithColors:(NSArray*)colors
                        sounds:(NSArray*)sounds
               averageInterval:(NSTimeInterval)averageInterval
            intervalRandomness:(NSTimeInterval)intervalRandomness
{
    return [[self alloc] initWithColors:colors
                                 sounds:sounds
                        averageInterval:averageInterval
                     intervalRandomness:intervalRandomness];
}

-(instancetype)initWithColors:(NSArray*)colors
                       sounds:(NSArray*)sounds
              averageInterval:(NSTimeInterval)averageInterval
           intervalRandomness:(NSTimeInterval)intervalRandomness
{
    self = [super init];
    if (self)
    {
        self.colors = colors;
        self.sounds = sounds;
        self.averageInterval = averageInterval;
        self.intervalRandomness = intervalRandomness;
    }
    
    return self;
}


-(void)playNextSound:(NSTimer*)timer
{
    VPLSound *sound = self.sounds[self.currentSound];
    [sound play];
    
    self.currentSound++;
    if (self.currentSound < self.sounds.count)
    {
        self.soundTimer = [NSTimer scheduledTimerWithTimeInterval:sound.duration - sound.durationOverlap
                                                           target:self
                                                         selector:@selector(playNextSound:)
                                                         userInfo:nil
                                                          repeats:NO];
    }
    else
    {
        self.soundTimer = nil;
    }
}

-(void)applyNextColor:(NSTimer*)timer
{
    VPLColor *color = self.colors[self.currentColor];

    if (color.applyToAllLamps)
    {
        for (DPHueLight *lamp in self.lamps)
        {
            [color applyToLamp:lamp];
        }
    }
    else
    {
        DPHueLight *lamp = self.lamps[self.currentLamp];
        [color applyToLamp:lamp];
        self.currentLamp++;
        if (self.currentLamp == self.lamps.count)
        {
            self.currentLamp = 0;
        }
    }
    
    
    self.currentColor++;
    if (self.currentColor < self.colors.count)
    {
        NSTimeInterval duration = color.duration - color.durationRandomness / 2;
        duration += (color.durationRandomness / 100.0f) * (arc4random() % 100);
        
        self.colorTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                           target:self
                                                         selector:@selector(applyNextColor:)
                                                         userInfo:nil
                                                          repeats:NO];
    }
    else
    {
        self.colorTimer = nil;
        if (self.colorsCompletion)
        {
            self.colorsCompletion();
        }
    }
}

-(void)playEventWithLamps:(NSArray*)lamps // of DPHueLight's
         colorsCompletion:(VPLEventColorsCompletedHanlder)colorsBlock
{
    DLog(@"playing %lu colors, %lu sounds", (unsigned long)self.colors.count, (unsigned long)self.sounds.count);
    self.currentColor = 0;
    self.currentSound = 0;
    self.lamps = lamps;
    if (self.lamps.count)
    {
        self.currentLamp = arc4random() % lamps.count;
    }
    else
    {
        self.currentLamp = 0;
    }
    self.colorsCompletion = colorsBlock;
    
    if (self.sounds.count)
    {
        [self playNextSound:nil];
    }
    
    if ((self.colors.count) && (lamps.count))
    {
        if ([VPLSoundManager sharedManager].volumeView.wirelessRouteActive)
        {
            self.colorTimer = [NSTimer scheduledTimerWithTimeInterval:kVPLEventWirelessAudioDelay
                                                               target:self
                                                             selector:@selector(applyNextColor:)
                                                             userInfo:nil
                                                              repeats:NO];
        }
        else
        {
            [self applyNextColor:nil];
        }
    }
    else
    {
        if (colorsBlock)
        {
            colorsBlock();
        }
    }
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<VPLEvent: interval=%.2f, colors=%@, sounds=%@>", self.averageInterval, self.colors, self.sounds];
}

@end
