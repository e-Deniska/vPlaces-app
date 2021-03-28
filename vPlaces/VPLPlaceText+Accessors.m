//
//  VPLPlaceText+Accessors.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlaceText+Accessors.h"
#import "VPLPlaceInfo.h"

@implementation VPLPlaceText (Accessors)

+(instancetype)existingTextWithLanguage:(NSString*)languge forPlaceInfo:(VPLPlaceInfo*)placeInfo
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaceText"];
    request.predicate = [NSPredicate predicateWithFormat:@"(info == %@) AND (language == %@)", placeInfo, languge];
    request.fetchLimit = 1;
    return [[placeInfo.managedObjectContext executeFetchRequest:request] lastObject];
}

+(instancetype)textWithLanguage:(NSString*)languge forPlaceInfo:(VPLPlaceInfo*)placeInfo
{
    VPLPlaceText *placeText = [self existingTextWithLanguage:languge forPlaceInfo:placeInfo];
    if (!placeText)
    {
        placeText = [NSEntityDescription insertNewObjectForEntityForName:@"PlaceText"
                                                  inManagedObjectContext:placeInfo.managedObjectContext];
        placeText.info = placeInfo;
        placeText.language = languge;
    }
 
    return placeText;
}

@end
