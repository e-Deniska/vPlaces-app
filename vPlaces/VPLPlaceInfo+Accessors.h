//
//  VPLPlaceInfo+Accessors.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlaceInfo.h"

@class VPLPlace, VPLPlaceText;

@interface VPLPlaceInfo (Accessors)

+(instancetype)existingPlaceInfoWithUID:(NSString*)uid inContext:(NSManagedObjectContext*)context;
+(instancetype)placeInfoWithUID:(NSString*)uid inContext:(NSManagedObjectContext*)context;

+(NSUInteger)numberOfPlacesInContext:(NSManagedObjectContext*)context;
+(NSArray*)placesInContext:(NSManagedObjectContext*)context;
+(NSArray*)downloadedPlacesInContext:(NSManagedObjectContext*)context;
+(NSArray*)availablePlacesInContext:(NSManagedObjectContext*)context;

+(void)resetDownloadProgressInContext:(NSManagedObjectContext*)context;
+(void)removeAllPlacesInContext:(NSManagedObjectContext*)context;

@property (nonatomic, readonly) NSURL *archiveURL;

@property (nonatomic, readonly) VPLPlaceText *defaultText;

@property (nonatomic, readonly) VPLPlace *place;

@property (nonatomic, readonly, getter = isDownloaded) BOOL downloaded;

@end
