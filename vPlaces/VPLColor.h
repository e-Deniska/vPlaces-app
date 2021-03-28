//
//  VPLColor.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHueLight.h"

@interface VPLColor : NSObject

@property (nonatomic, assign, readonly) int hue; // 0..255
@property (nonatomic, assign, readonly) int saturation; // 0..255
@property (nonatomic, assign, readonly) int brightness; // 0..255

@property (nonatomic, assign, readonly) int brightnessRandomness;

@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) NSTimeInterval durationRandomness;

@property (nonatomic, assign, readonly) BOOL smoothTransition;

@property (nonatomic, assign, readonly) BOOL applyToAllLamps;


-(instancetype)initWithHue:(int)hue
                saturation:(int)saturation
                brightness:(int)brightness
      brightnessRandomness:(int)brightnessRandomness
                  duration:(NSTimeInterval)duration
        durationRandomness:(NSTimeInterval)durationRandomness
          smoothTransition:(BOOL)smoothTransition
                  allLamps:(BOOL)allLamps;

+(instancetype)colorWithHue:(int)hue
                 saturation:(int)saturation
                 brightness:(int)brightness
       brightnessRandomness:(int)brightnessRandomness
                   duration:(NSTimeInterval)duration
         durationRandomness:(NSTimeInterval)durationRandomness
           smoothTransition:(BOOL)smoothTransition
                   allLamps:(BOOL)allLamps;

-(void)applyToLamp:(DPHueLight*)lamp;

@end
