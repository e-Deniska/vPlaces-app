//
//  NSUserDefaults+Accessors.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Accessors)

@property (nonatomic, copy) NSString *hueName;
@property (nonatomic, readonly) NSString *appUsername;

@property (nonatomic, copy) NSArray *lampNumbers;

@property (nonatomic, assign) BOOL bundlePlacesOffered;

@property (nonatomic, assign) BOOL allowCellularAccess;

@property (nonatomic, copy) NSDate *lastBundlePlaceListUpdate;


@end
