//
//  VPLPlaceManager.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 25.02.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kVPLDefaultLanguage;
extern NSString * const VPLPlaceDownloadedNotification;

typedef void (^VPLPlaceManagerCompletion)(BOOL success);
typedef void (^VPLURLSessionCompletion)();


@class VPLPlace;

@interface VPLPlaceManager : NSObject

@property (nonatomic, strong, readonly) NSArray *places;
@property (nonatomic, copy) VPLURLSessionCompletion sessionCompletion;
@property (nonatomic, assign) BOOL allowCellularAccess;

+(instancetype)manager;
-(NSURL*)unpackPlaceArchiveAtURL:(NSURL*)archiveURL deleteOriginal:(BOOL)deleteOriginal;
-(void)loadLocalPlaces;

-(void)updateRemotePlacesListWithCompletion:(VPLPlaceManagerCompletion)completion;

-(void)downloadPlaceAtURL:(NSURL*)url
               identifier:(NSString*)identifier
               completion:(VPLPlaceManagerCompletion)completion;

-(BOOL)removePlace:(VPLPlace*)place;

@end
