//
//  VPLEvent.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^VPLEventColorsCompletedHanlder)();

@interface VPLEvent : NSObject

@property (nonatomic, copy, readonly) NSArray *colors; // of VPLColor's
@property (nonatomic, copy, readonly) NSArray *sounds; // of VPLSound's

@property (nonatomic, assign, readonly) NSTimeInterval averageInterval;
@property (nonatomic, assign, readonly) NSTimeInterval intervalRandomness;

-(void)playEventWithLamps:(NSArray*)lamps // of DPHueLight's
         colorsCompletion:(VPLEventColorsCompletedHanlder)colorsBlock;

-(instancetype)initWithColors:(NSArray*)colors
                       sounds:(NSArray*)sounds
              averageInterval:(NSTimeInterval)averageInterval
           intervalRandomness:(NSTimeInterval)intervalRandomness;

+(instancetype)eventWithColors:(NSArray*)colors
                        sounds:(NSArray*)sounds
               averageInterval:(NSTimeInterval)averageInterval
            intervalRandomness:(NSTimeInterval)intervalRandomness;

@end
