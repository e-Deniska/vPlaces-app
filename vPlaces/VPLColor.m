//
//  VPLColor.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLColor.h"

@interface VPLColor()

@property (nonatomic, assign, readwrite) int hue; // 0..255
@property (nonatomic, assign, readwrite) int saturation; // 0..255
@property (nonatomic, assign, readwrite) int brightness; // 0..255

@property (nonatomic, assign, readwrite) int brightnessRandomness;

@property (nonatomic, assign, readwrite) NSTimeInterval duration;

@property (nonatomic, assign, readwrite) NSTimeInterval durationRandomness;

@property (nonatomic, assign, readwrite) BOOL smoothTransition;

@property (nonatomic, assign, readwrite) BOOL applyToAllLamps;

@end

@implementation VPLColor

-(void)applyToLamp:(DPHueLight*)lamp
{
    int brightness = self.brightness + (arc4random() % self.brightnessRandomness) - (self.brightnessRandomness / 2);
    lamp.on = (brightness > 0);
    if (brightness > 0)
    {
        lamp.brightness = @(MAX(0, MIN(255, brightness)));
        lamp.hue = @(self.hue);
        lamp.saturation = @(self.saturation);
        if (self.smoothTransition)
        {
            int transitionTime = (int)(self.duration * 10);
            lamp.transitionTime = @(transitionTime);
        }
        else
        {
            lamp.transitionTime = nil;
        }
    }
    DLog(@"[%@] - (%d,%d,%d)", lamp.name, self.hue, self.saturation, brightness);
    
    [lamp write];
}

+(instancetype)colorWithHue:(int)hue
                 saturation:(int)saturation
                 brightness:(int)brightness
       brightnessRandomness:(int)brightnessRandomness
                   duration:(NSTimeInterval)duration
         durationRandomness:(NSTimeInterval)durationRandomness
           smoothTransition:(BOOL)smoothTransition
                   allLamps:(BOOL)allLamps
{
    return [[self alloc] initWithHue:hue
                          saturation:saturation
                          brightness:brightness
                brightnessRandomness:brightnessRandomness
                            duration:duration
                  durationRandomness:durationRandomness
                    smoothTransition:smoothTransition
                            allLamps:allLamps];
}

-(instancetype)initWithHue:(int)hue
                saturation:(int)saturation
                brightness:(int)brightness
      brightnessRandomness:(int)brightnessRandomness
                  duration:(NSTimeInterval)duration
        durationRandomness:(NSTimeInterval)durationRandomness
          smoothTransition:(BOOL)smoothTransition
                  allLamps:(BOOL)allLamps
{
    self = [super init];
    if (self)
    {
        self.hue = hue;
        self.saturation = saturation;
        self.brightness = brightness;
        self.brightnessRandomness = brightnessRandomness;
        self.duration = duration;
        self.durationRandomness = durationRandomness;
        self.smoothTransition = smoothTransition;
        self.applyToAllLamps = allLamps;
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<VPLColor: hue=%d, bri=%d, sat=%d>", self.hue, self.saturation, self.brightness];
}

@end
