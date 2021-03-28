//
//  VPLPlaceInfo+Accessors.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlaceInfo+Accessors.h"
#import "VPLPlaceText+Accessors.h"
#import "VPLPlaceManager.h"
#import "VPLPlace.h"

@implementation VPLPlaceInfo (Accessors)

+(void)resetDownloadProgressInContext:(NSManagedObjectContext *)context
{
    NSArray *places = [self placesInContext:context];
    for (VPLPlaceInfo *placeInfo in places)
    {
        placeInfo.downloadedSize = 0;
        placeInfo.totalSize = 0;
    }
}

+(void)removeAllPlacesInContext:(NSManagedObjectContext*)context
{
    NSArray *places = [self placesInContext:context];
    for (VPLPlaceInfo *placeInfo in places)
    {
        [context deleteObject:placeInfo];
    }
}


+(instancetype)existingPlaceInfoWithUID:(NSString*)uid inContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaceInfo"];
    request.predicate = [NSPredicate predicateWithFormat:@"uid == %@", uid];
    request.fetchLimit = 1;
    return [[context executeFetchRequest:request] lastObject];
}

+(instancetype)placeInfoWithUID:(NSString*)uid inContext:(NSManagedObjectContext*)context
{
    VPLPlaceInfo *placeInfo = [self existingPlaceInfoWithUID:uid inContext:context];
    if (!placeInfo)
    {
        placeInfo = [NSEntityDescription insertNewObjectForEntityForName:@"PlaceInfo"
                                                  inManagedObjectContext:context];
        placeInfo.uid = uid;
    }
    return placeInfo;
}

+(NSUInteger)numberOfPlacesInContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaceInfo"];
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES] ];
    return [context countForFetchRequest:request];
}

+(NSArray*)placesInContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaceInfo"];
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES] ];
    return [context executeFetchRequest:request];
}

+(NSArray*)downloadedPlacesInContext:(NSManagedObjectContext*)context
{
    NSArray *allPlaces = [self placesInContext:context];
    NSMutableArray *downloadedPlaces = [NSMutableArray arrayWithCapacity:allPlaces.count];
    for (VPLPlaceInfo *placeInfo in allPlaces)
    {
        if (placeInfo.downloaded)
        {
            [downloadedPlaces addObject:placeInfo];
        }
    }
    return [downloadedPlaces copy];
}

+(NSArray*)availablePlacesInContext:(NSManagedObjectContext*)context
{
    NSArray *allPlaces = [self placesInContext:context];
    NSMutableArray *availablePlaces = [NSMutableArray arrayWithCapacity:allPlaces.count];
    for (VPLPlaceInfo *placeInfo in allPlaces)
    {
        if (!placeInfo.downloaded)
        {
            [availablePlaces addObject:placeInfo];
        }
    }
    return [availablePlaces copy];
}



-(NSURL *)archiveURL
{
    return [NSURL URLWithString:self.archiveLink];
}

-(VPLPlaceText *)defaultText
{
    NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
    for (VPLPlaceText *text in self.texts)
    {
        if ([text.language isEqualToString:localization])
        {
            return text;
        }
    }
    
    return [VPLPlaceText existingTextWithLanguage:kVPLDefaultLanguage forPlaceInfo:self];
}

-(BOOL)isDownloaded
{
    return (self.place != nil);
}

-(VPLPlace *)place
{
    NSArray *places = [VPLPlaceManager manager].places;
    for (VPLPlace *place in places)
    {
        if ([place.identifier isEqualToString:self.uid])
        {
            return place;
        }
    }
    return nil;
}

@end
