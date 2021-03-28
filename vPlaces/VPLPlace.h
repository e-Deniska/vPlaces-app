//
//  VPLPlace.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPLAnimatedImageView.h"

@interface VPLPlace : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSURL *baseURL;

@property (nonatomic, copy, readonly) NSString *detailedInfo;
@property (nonatomic, weak) VPLAnimatedImageView *animatedImageView;


-(void)startPresentingPlaceWithAnimatedImageView:(VPLAnimatedImageView*)animatedImageView
                                           lamps:(NSArray*)lamps; // of DPHueLight's
-(void)stopPresentingPlace;

@property (nonatomic, readonly) UIImage *coverImage;


+(instancetype)placeWithIdentifier:(NSString*)identifier
                           baseURL:(NSURL*)baseURL
                             title:(NSString*)title
                      detailedInfo:(NSString*)detailedInfo
                     ambientColors:(NSArray*)colors // of VPLColor's
                     ambientSounds:(NSArray*)sounds // of VPLSound's
                            images:(NSArray*)images //of VPLImage's
                            events:(NSArray*)events; // of VPLEvent's

-(instancetype)initWithIdentifier:(NSString*)identifier
                          baseURL:(NSURL*)baseURL
                            title:(NSString*)title
                     detailedInfo:(NSString*)detailedInfo
                    ambientColors:(NSArray*)colors // of VPLColor's
                    ambientSounds:(NSArray*)sounds // of VPLSound's
                           images:(NSArray*)images //of VPLImage's
                           events:(NSArray*)events; // of VPLEvent's

@end