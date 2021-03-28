//
//  VPLPlaceText+Accessors.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlaceText.h"

@class VPLPlaceInfo;

@interface VPLPlaceText (Accessors)

+(instancetype)existingTextWithLanguage:(NSString*)languge forPlaceInfo:(VPLPlaceInfo*)placeInfo;
+(instancetype)textWithLanguage:(NSString*)languge forPlaceInfo:(VPLPlaceInfo*)placeInfo;

@end
