//
//  VPLPlaceText.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VPLPlaceInfo;

@interface VPLPlaceText : NSManagedObject

@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) VPLPlaceInfo *info;

@end
