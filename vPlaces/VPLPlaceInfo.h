//
//  VPLPlaceInfo.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 21.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VPLPlaceText;

@interface VPLPlaceInfo : NSManagedObject

@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * archiveLink;
@property (nonatomic, retain) NSString * localRevision;
@property (nonatomic, retain) NSString * remoteRevision;
@property (nonatomic, assign) int64_t downloadedSize;
@property (nonatomic, assign) int64_t reportedSize;
@property (nonatomic, assign) int64_t totalSize;


@property (nonatomic, retain) NSSet *texts;
@end

@interface VPLPlaceInfo (CoreDataGeneratedAccessors)

- (void)addTextsObject:(VPLPlaceText *)value;
- (void)removeTextsObject:(VPLPlaceText *)value;
- (void)addTexts:(NSSet *)values;
- (void)removeTexts:(NSSet *)values;

@end
