//
//  VPLPlace.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlace.h"
#import "VPLImage.h"
#import "VPLSound.h"
#import "VPLColor.h"
#import "VPLEvent.h"
#import "VPLSoundManager.h"

#define kVPLLampKey @"VPLLampKey"

@interface VPLPlace()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSURL *baseURL;

@property (nonatomic, copy, readwrite) NSString *detailedInfo;

@property (nonatomic, copy) NSArray *ambientSounds; // of VPLSound's

@property (nonatomic, copy) NSArray *ambientColors; // of VPLColor's

@property (nonatomic, copy) NSArray *images; // of VPLImage's

@property (nonatomic, copy) NSArray *events; // of VPLEvent's

@property (nonatomic, assign) int coverImageIndex;

@property (nonatomic, strong) NSTimer *ambientSoundTimer;
@property (nonatomic, strong) NSTimer *ambientImageTimer;
@property (nonatomic, strong) NSTimer *eventTimer;

@property (nonatomic, strong) NSMutableArray *ambientColorTimers;

@property (nonatomic, weak) VPLEvent *scheduledEvent;

@property (nonatomic, strong) NSArray *lamps;

@end

@implementation VPLPlace

+(instancetype)placeWithIdentifier:(NSString*)identifier
                           baseURL:(NSURL*)baseURL
                             title:(NSString*)title
                      detailedInfo:(NSString*)detailedInfo
                     ambientColors:(NSArray*)colors // of VPLColor's
                     ambientSounds:(NSArray*)sounds // of VPLSound's
                            images:(NSArray*)images //of VPLImage's
                            events:(NSArray*)events // of VPLEvent's
{
    return [[self alloc] initWithIdentifier:identifier
                                    baseURL:baseURL
                                      title:title
                               detailedInfo:detailedInfo
                              ambientColors:colors
                              ambientSounds:sounds
                                     images:images
                                     events:events];
}

-(instancetype)initWithIdentifier:(NSString*)identifier
                          baseURL:(NSURL*)baseURL
                            title:(NSString*)title
                     detailedInfo:(NSString*)detailedInfo
                    ambientColors:(NSArray*)colors // of VPLColor's
                    ambientSounds:(NSArray*)sounds // of VPLSound's
                           images:(NSArray*)images //of VPLImage's
                           events:(NSArray*)events // of VPLEvent's
{
    self = [super init];
    if (self)
    {
        self.identifier = identifier;
        self.baseURL = baseURL;
        self.title = title;
        self.detailedInfo = detailedInfo;
        self.ambientColors = colors;
        self.ambientSounds = sounds;
        self.images = images;
        self.events = events;
        if (self.images.count)
        {
            self.coverImageIndex = arc4random() % self.images.count;
        }
    }
    return self;
}



-(UIImage*)coverImage
{
    VPLImage *image = self.images[self.coverImageIndex];
    return image.image;
}

-(void)startPresentingPlaceWithAnimatedImageView:(VPLAnimatedImageView*)animatedImageView
                                           lamps:(NSArray*)lamps; // of DPHueLight's
{
    self.animatedImageView = animatedImageView;
    self.lamps = lamps;
    [self showRandomAmbientImage:nil];
    [self playRandomAmbientSound:nil];
    [self scheduleEvent:nil];
    [self startAmbientColors];
}

-(void)stopPresentingPlace
{
    [self stopAmbientColors];
    
    [self.ambientImageTimer invalidate];
    [self.ambientSoundTimer invalidate];
    [self.eventTimer invalidate];
    self.ambientImageTimer = nil;
    self.ambientSoundTimer = nil;
    self.eventTimer = nil;
    self.scheduledEvent = nil;
    [[VPLSoundManager sharedManager] stopAllSounds];
    
}

-(void)scheduleEvent:(NSTimer*)timer
{
    if (self.scheduledEvent)
    {
        [self stopAmbientColors];
        
        [self.scheduledEvent playEventWithLamps:self.lamps
                               colorsCompletion:^{
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       DLog(@"event completed, resuming ambient colors");
                                       [self startAmbientColors];
                                   });
        }];
    }
    
    if (self.events.count)
    {
        self.scheduledEvent = self.events[arc4random() % self.events.count];
        NSTimeInterval interval = self.scheduledEvent.averageInterval - (self.scheduledEvent.intervalRandomness / 2);
        interval += (self.scheduledEvent.intervalRandomness / 100.0f) * (arc4random() % 100);
        
        DLog(@"scheduling event in %.2f", interval);
        self.eventTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                           target:self
                                                         selector:@selector(scheduleEvent:)
                                                         userInfo:nil
                                                          repeats:NO];
    }
}

-(void)showRandomAmbientImage:(NSTimer*)timer
{
    if (self.images.count)
    {
        VPLImage *image = timer ? self.images[arc4random() % self.images.count] : self.images[self.coverImageIndex];
        DLog(@"presenting image %@ in %@", image.imageURL, self.animatedImageView);
        [image displayInAnimatedImageView:self.animatedImageView];
        
        NSTimeInterval interval = image.duration - (image.durationRandomness / 2);
        interval += (image.durationRandomness / 100.0f) * (arc4random() % 100);
        
        self.ambientImageTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                  target:self
                                                                selector:@selector(showRandomAmbientImage:)
                                                                userInfo:nil
                                                                 repeats:NO];
    }
}

-(void)playRandomAmbientSound:(NSTimer*)timer
{
    if (self.ambientSounds.count)
    {
        VPLSound *sound = self.ambientSounds[arc4random() % self.ambientSounds.count];
        DLog(@"playing sound %@", sound.soundURL);
        [sound play];
        
        self.ambientSoundTimer = [NSTimer scheduledTimerWithTimeInterval:sound.duration - sound.durationOverlap
                                                                  target:self
                                                                selector:@selector(playRandomAmbientSound:)
                                                                userInfo:nil
                                                                 repeats:NO];
    }
}

-(void)startAmbientColors
{
    if ((self.ambientColors.count) && (self.lamps.count))
    {
        self.ambientColorTimers = [NSMutableArray arrayWithCapacity:self.lamps.count];
        for (DPHueLight *lamp in self.lamps)
        {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                              target:self
                                                            selector:@selector(applyRandomAmbientColor:)
                                                            userInfo:@{ kVPLLampKey : lamp }
                                                             repeats:NO];
            [self.ambientColorTimers addObject:timer];
        }
    }
}

-(void)stopAmbientColors
{
    for (NSTimer *timer in self.ambientColorTimers)
    {
        [timer invalidate];
    }
    self.ambientColorTimers = nil;
}

-(void)applyRandomAmbientColor:(NSTimer*)timer
{
    DPHueLight *lamp = timer.userInfo[kVPLLampKey];
    [self.ambientColorTimers removeObject:timer];
    
    VPLColor *color = self.ambientColors[arc4random() % self.ambientColors.count];
    NSTimeInterval interval = color.duration - (color.durationRandomness / 2);
    interval += (color.durationRandomness / 100.0f) * (arc4random() % 100);
    
    [color applyToLamp:lamp];
    
    NSTimer *nextTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(applyRandomAmbientColor:)
                                                        userInfo:@{ kVPLLampKey : lamp }
                                                         repeats:NO];
    [self.ambientColorTimers addObject:nextTimer];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<VPLPlace: title=%@, detailedInfo=%@, colors=%@, images=%@, sounds=%@, events=%@>", self.title, self.detailedInfo, self.ambientColors, self.images, self.ambientSounds, self.events];
}

@end
