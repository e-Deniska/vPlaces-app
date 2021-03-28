//
//  VPLPlaceManager.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 25.02.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import "VPLPlaceManager.h"
#import "VPLPlace.h"

#import "VPLColor.h"
#import "VPLImage.h"
#import "VPLSound.h"
#import "VPLEvent.h"

#import "VPLPlaceInfo+Accessors.h"
#import "VPLPlaceText+Accessors.h"

#import "SSZipArchive.h"

#define kVPLBunldePlaceListUpdateInterval 80000.0f

NSString * const VPLPlaceDownloadedNotification = @"VPLPlaceDownloadedNotification";

NSString * const kVPLRemotePlacesURL     = @"https://e-deniska.github.io/vPlaces/places.json";


NSString * const kVPLPlacesDirectory     = @"places";


NSString * const kVPLDefinitionFile      = @"vplace.json";

NSString * const kVPLSupportedVersion    = @"1.0";

NSString * const kVPLVersionKey          = @"version";

NSString * const kVPLRevisionKey         = @"revision";
NSString * const kVPLArchiveURLKey       = @"archiveURL";
NSString * const kVPLFileSizeKey         = @"fileSize";


NSString * const kVPLPlacesKey           = @"places";

NSString * const kVPLTextsKey            = @"texts";
NSString * const kVPLLanguageKey         = @"lang";
NSString * const kVPLTitleKey            = @"title";
NSString * const kVPLDetailsKey          = @"details";

NSString * const kVPLIdentifierKey       = @"identifier";

NSString * const kVPLDefaultLanguage     = @"en";

NSString * const kVPLDurationKey         = @"duration";
NSString * const kVPLDurationRandomKey   = @"durationRandomness";

NSString * const kVPLImagesKey           = @"images";
NSString * const kVPLImageURLKey         = @"file";

NSString * const kVPLSoundsKey           = @"sounds";
NSString * const kVPLSoundURLKey         = @"file";
NSString * const kVPLSoundOverlapKey     = @"overlapDuration";
NSString * const kVPLStartDelayKey       = @"startDelay";
NSString * const kVPLMuteOthersKey       = @"muteOther";
NSString * const kVPLSimultaneouslyKey   = @"playSimultaneously";

NSString * const kVPLColorsKey           = @"colors";
NSString * const kVPLHueKey              = @"hue";
NSString * const kVPLSaturationKey       = @"saturation";
NSString * const kVPLBrightnessKey       = @"brightness";
NSString * const kVPLBrightnessRandomKey = @"brightnessRandomness";
NSString * const kVPLSmoothKey           = @"smoothTransition";
NSString * const kVPLApplyToAllKey       = @"applyToAllLamps";

NSString * const kVPLEventsKey           = @"events";
NSString * const kVPLAverageIntervalKey  = @"averageInterval";
NSString * const kVPLIntervalRandomKey   = @"intervalRandomness";

int const kVPLHTTPStatusOk = 200;

@interface VPLPlaceManager() <NSURLSessionDownloadDelegate>

@property (nonatomic, readonly) NSURL *placesURL;
@property (nonatomic, readonly, strong) NSFileManager *fileManager;
@property (nonatomic, strong, readwrite) NSArray *places;
@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSURLSession *querySession;
@property (nonatomic, strong) NSMutableDictionary *completionHanlders;

@property (nonatomic, strong) dispatch_queue_t unpackQueue;

@end

@implementation VPLPlaceManager

+(instancetype)manager
{
    static dispatch_once_t onceToken;
    static VPLPlaceManager * _manager;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
        NSURLSessionConfiguration *confiugration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.tazetdinov.vplaces.download"];
        confiugration.allowsCellularAccess = [NSUserDefaults standardUserDefaults].allowCellularAccess;
        _manager.downloadSession = [NSURLSession sessionWithConfiguration:confiugration
                                                                 delegate:_manager
                                                            delegateQueue:[NSOperationQueue mainQueue]];
        _manager.querySession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                              delegate:_manager
                                                         delegateQueue:[NSOperationQueue mainQueue]];
        _manager.completionHanlders = [NSMutableDictionary dictionary];
        _manager.unpackQueue = dispatch_queue_create("com.tazetdinov.vplaces.unpack", DISPATCH_QUEUE_SERIAL);
        
    });
    return _manager;
}

-(BOOL)allowCellularAccess
{
    return [NSUserDefaults standardUserDefaults].allowCellularAccess;
}

-(void)setAllowCellularAccess:(BOOL)allowCellularAccess
{
    [NSUserDefaults standardUserDefaults].allowCellularAccess = allowCellularAccess;
    self.downloadSession.configuration.allowsCellularAccess = allowCellularAccess;
}

-(NSFileManager *)fileManager
{
    static dispatch_once_t onceToken;
    static NSFileManager *_fileManager;
    dispatch_once(&onceToken, ^{
        _fileManager = [[NSFileManager alloc] init];
    });
    return _fileManager;
}


-(VPLColor*)colorWithDictionary:(NSDictionary*)dict
{
    NSArray *keys = dict.allKeys;
    if (([keys containsObject:kVPLHueKey]) &&
        ([keys containsObject:kVPLSaturationKey]) &&
        ([keys containsObject:kVPLBrightnessKey]) &&
        ([keys containsObject:kVPLBrightnessRandomKey]) &&
        ([keys containsObject:kVPLDurationKey]) &&
        ([keys containsObject:kVPLDurationRandomKey]) &&
        ([keys containsObject:kVPLSmoothKey]) &&
        ([keys containsObject:kVPLApplyToAllKey]))
    {
        int hue                       = [dict[kVPLHueKey] intValue];
        int sat                       = [dict[kVPLSaturationKey] intValue];
        int bri                       = [dict[kVPLBrightnessKey] intValue];
        int briRandom                 = [dict[kVPLBrightnessRandomKey] intValue];
        NSTimeInterval duration       = [dict[kVPLDurationKey] doubleValue];
        NSTimeInterval durationRandom = [dict[kVPLDurationRandomKey] doubleValue];
        BOOL smooth                   = [dict[kVPLSmoothKey] boolValue];
        BOOL applyToAll               = [dict[kVPLApplyToAllKey] boolValue];
        
        return [VPLColor colorWithHue:hue
                           saturation:sat
                           brightness:bri
                 brightnessRandomness:briRandom
                             duration:duration
                   durationRandomness:durationRandom
                     smoothTransition:smooth
                             allLamps:applyToAll];
    }
    else
    {
        DLog(@"dict is missing required parts %@", dict);
        return nil;
    }
}

-(VPLImage*)imageWithDictionary:(NSDictionary*)dict baseURL:(NSURL*)baseURL
{
    NSArray *keys = dict.allKeys;
    if (([keys containsObject:kVPLImageURLKey]) &&
        ([keys containsObject:kVPLDurationKey]) &&
        ([keys containsObject:kVPLDurationRandomKey]))
    {
        NSURL *url                    = [baseURL URLByAppendingPathComponent:dict[kVPLImageURLKey]];
        NSTimeInterval duration       = [dict[kVPLDurationKey] doubleValue];
        NSTimeInterval durationRandom = [dict[kVPLDurationRandomKey] doubleValue];
        
        NSError * __autoreleasing error;
        if ([url checkResourceIsReachableAndReturnError:&error])
        {
            return [VPLImage imageWithImageURL:url
                                      duration:duration
                                    randomness:durationRandom];
        }
        else
        {
            DLog(@"could not find image at %@", url);
            return nil;
        }
    }
    else
    {
        DLog(@"dict is missing required parts %@", dict);
        return nil;
    }
}

-(VPLSound*)soundWithDictionary:(NSDictionary*)dict baseURL:(NSURL*)baseURL
{
    NSArray *keys = dict.allKeys;
    if (([keys containsObject:kVPLSoundURLKey]) &&
        ([keys containsObject:kVPLSoundOverlapKey]) &&
        ([keys containsObject:kVPLStartDelayKey]) &&
        ([keys containsObject:kVPLSimultaneouslyKey]) &&
        ([keys containsObject:kVPLMuteOthersKey]))
    {
        NSURL *url                     = [baseURL URLByAppendingPathComponent:dict[kVPLSoundURLKey]];
        NSTimeInterval durationOverlap = [dict[kVPLSoundOverlapKey] doubleValue];
        NSTimeInterval startDelay      = [dict[kVPLStartDelayKey] doubleValue];
        BOOL playSimultaneously        = [dict[kVPLSimultaneouslyKey] boolValue];
        BOOL muteOthers                = [dict[kVPLMuteOthersKey] boolValue];
        
        NSError * __autoreleasing error;
        if ([url checkResourceIsReachableAndReturnError:&error])
        {
            return [VPLSound soundWithSoundURL:url
                               durationOverlap:durationOverlap
                                    startDelay:startDelay
                            playSimultaneously:playSimultaneously
                               muteOtherSounds:muteOthers];
        }
        else
        {
            DLog(@"could not find sound at %@", url);
            return nil;
        }
    }
    else
    {
        DLog(@"dict is missing required parts %@", dict);
        return nil;
    }
}

-(VPLEvent*)eventWithDictionary:(NSDictionary*)dict baseURL:(NSURL*)baseURL
{
    NSArray *keys = dict.allKeys;
    if (([keys containsObject:kVPLAverageIntervalKey]) &&
        ([keys containsObject:kVPLIntervalRandomKey]))
    {
        NSTimeInterval interval       = [dict[kVPLAverageIntervalKey] doubleValue];
        NSTimeInterval intervalRandom = [dict[kVPLIntervalRandomKey] doubleValue];
        
        // ambient colors
        NSArray *colorDicts = dict[kVPLColorsKey];
        NSMutableArray *colors = [NSMutableArray arrayWithCapacity:colorDicts.count];
        for (NSDictionary *colorDict in colorDicts)
        {
            VPLColor *color = [self colorWithDictionary:colorDict];
            if (color)
            {
                [colors addObject:color];
            }
        }
        
        // ambient sounds
        NSArray *soundDicts = dict[kVPLSoundsKey];
        NSMutableArray *sounds = [NSMutableArray arrayWithCapacity:soundDicts.count];
        for (NSDictionary *soundDict in soundDicts)
        {
            VPLSound *sound = [self soundWithDictionary:soundDict baseURL:baseURL];
            if (sound)
            {
                [sounds addObject:sound];
            }
        }
        
        return [VPLEvent eventWithColors:[colors copy]
                                  sounds:[sounds copy]
                         averageInterval:interval
                      intervalRandomness:intervalRandom];
    }
    else
    {
        DLog(@"dict is missing required parts %@", dict);
        return nil;
    }
}

-(void)removeInvalidPlaceAtURL:(NSURL*)url
{
    DLog(@"removing invalid place at %@", url);
    NSError * __autoreleasing error;
    if (![self.fileManager removeItemAtURL:url error:&error])
    {
        DLog(@"problems deleting place at %@ - %@", url, error);
    }
}

-(VPLPlace*)placeWithBaseURL:(NSURL*)baseURL
{
    NSData *rootData = [NSData dataWithContentsOfURL:[baseURL URLByAppendingPathComponent:kVPLDefinitionFile]];
    
    if (!rootData)
    {
        DLog(@"could load definition file - %@", baseURL);
        [self removeInvalidPlaceAtURL:baseURL];
        return nil;
    }
    
    NSError * __autoreleasing error;
    
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:rootData
                                                         options:0
                                                           error:&error];
    if ((error) || (!root))
    {
        DLog(@"could not load/parse definition file - %@, %@", root, error);
        [self removeInvalidPlaceAtURL:baseURL];
        return nil;
    }
    
    // metadata check
    NSString *version = root[kVPLVersionKey];
    if ([version compare:kVPLSupportedVersion options:NSNumericSearch] == NSOrderedDescending)
    {
        DLog(@"file version is higher than supported %@ > %@", version, kVPLSupportedVersion);
        [self removeInvalidPlaceAtURL:baseURL];
        return nil;
    }
    
    NSString *identifier = root[kVPLIdentifierKey];
    if (!identifier.length)
    {
        DLog(@"each place should have identifier");
        [self removeInvalidPlaceAtURL:baseURL];
        return nil;
    }
    for (VPLPlace *place in self.places)
    {
        if ([identifier isEqualToString:place.identifier])
        {
            DLog(@"place with identifier %@ already loaded", identifier);
            return nil;
        }
    }
    
    // title and details
    NSDictionary *allTexts = root[kVPLTextsKey];
    NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
    NSDictionary *texts;
    for (NSDictionary *textsDict in allTexts)
    {
        if ([textsDict[kVPLLanguageKey] isEqualToString:localization])
        {
            texts = textsDict;
            break;
        }
    }
    
    if (!texts)
    {
        texts = allTexts[kVPLDefaultLanguage];
    }
    NSString *title        = texts[kVPLTitleKey];
    NSString *detailedInfo = texts[kVPLDetailsKey];
    
    // ambient colors
    NSArray *colorDicts = root[kVPLColorsKey];
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:colorDicts.count];
    for (NSDictionary *colorDict in colorDicts)
    {
        VPLColor *color = [self colorWithDictionary:colorDict];
        if (color)
        {
            [colors addObject:color];
        }
    }
    
    // ambient sounds
    NSArray *soundDicts = root[kVPLSoundsKey];
    NSMutableArray *sounds = [NSMutableArray arrayWithCapacity:soundDicts.count];
    for (NSDictionary *soundDict in soundDicts)
    {
        VPLSound *sound = [self soundWithDictionary:soundDict baseURL:baseURL];
        if (sound)
        {
            [sounds addObject:sound];
        }
    }
    
    // images
    NSArray *imageDicts = root[kVPLImagesKey];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:imageDicts.count];
    for (NSDictionary *imageDict in imageDicts)
    {
        VPLImage *image = [self imageWithDictionary:imageDict baseURL:baseURL];
        if (image)
        {
            [images addObject:image];
        }
    }
    
    // events
    NSArray *eventDicts = root[kVPLEventsKey];
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:eventDicts.count];
    for (NSDictionary *eventDict in eventDicts)
    {
        VPLEvent *event = [self eventWithDictionary:eventDict baseURL:baseURL];
        if (event)
        {
            [events addObject:event];
        }
    }
    
    return [VPLPlace placeWithIdentifier:identifier
                                 baseURL:baseURL
                                   title:title
                            detailedInfo:detailedInfo
                           ambientColors:[colors copy]
                           ambientSounds:[sounds copy]
                                  images:[images copy]
                                  events:[events copy]];
}

-(NSURL*)placesURL
{
    static dispatch_once_t onceToken;
    static NSURL *_placesURL;
    dispatch_once(&onceToken, ^{
        NSURL *documents = [[self.fileManager URLsForDirectory:NSDocumentDirectory
                                                     inDomains:NSUserDomainMask] firstObject];
        _placesURL = [documents URLByAppendingPathComponent:kVPLPlacesDirectory isDirectory:YES];
    });
    NSError * __autoreleasing error;
    if (![_placesURL checkResourceIsReachableAndReturnError:&error])
    {
        error = nil;
        if (![self.fileManager createDirectoryAtURL:_placesURL
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error])
        {
            DLog(@"could not create places directory at %@ - %@", _placesURL, error);
        }
    }
    return _placesURL;
}

-(NSURL*)unpackPlaceArchiveAtURL:(NSURL*)archiveURL deleteOriginal:(BOOL)deleteOriginal
{
    NSError * __autoreleasing error;
    if ([archiveURL checkResourceIsReachableAndReturnError:&error])
    {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSURL *resultURL = [self.placesURL URLByAppendingPathComponent:uuid isDirectory:YES];
        error = nil;
        if ([self.fileManager createDirectoryAtURL:resultURL
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error])
        {
            if (![resultURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error])
            {
                DLog(@"failed to set do-not-archive attribute for %@ - %@", resultURL, error);
                error = nil;
            }

            if ([SSZipArchive unzipFileAtPath:archiveURL.path toDestination:resultURL.path])
            {
                DLog(@"unpacked %@ to %@", archiveURL, resultURL);
                if (deleteOriginal)
                {
                    if (![self.fileManager removeItemAtURL:archiveURL error:&error])
                    {
                        DLog(@"problems removing original archive %@", error);
                        error = nil;
                    }
                }
                VPLPlace *place = [self placeWithBaseURL:resultURL];
                if (place)
                {
                    return resultURL;
                }
                else
                {
                    DLog(@"place could not be added, removing");
                    if (![self.fileManager removeItemAtURL:resultURL error:&error])
                    {
                        DLog(@"problems removing %@", error);
                    }
                    return nil;
                }
            }
            else
            {
                DLog(@"could not unpack %@ (%@) to %@ (%@)",
                     archiveURL, archiveURL.path, resultURL, resultURL.path);
                
                error = nil;
                if (![self.fileManager removeItemAtURL:resultURL error:&error])
                {
                    DLog(@"could not remove result directory %@", error);
                }
                
                return nil;
            }
        }
        else
        {
            DLog(@"could not create places directory at %@ - %@", resultURL, error);
            return nil;
        }
        
    }
    else
    {
        DLog(@"source archive could be opened %@", error);
        return nil;
    }
}

-(BOOL)removePlace:(VPLPlace*)place
{
    NSMutableArray *places = [self.places mutableCopy];
    [places removeObject:place];
    self.places = [places copy];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError * __autoreleasing error;
    BOOL success = [fm removeItemAtURL:place.baseURL error:&error];
    if (!success)
    {
        DLog(@"failed to delete place - %@", error);
    }
    return success;
}

-(NSArray*)URLsForLocalPlaces
{
    NSError * __autoreleasing error;
    NSArray *urls = [self.fileManager contentsOfDirectoryAtURL:self.placesURL
                                    includingPropertiesForKeys:nil
                                                       options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                         error:&error];
    if ((!urls) || (error))
    {
        DLog(@"could not list files - %@, %@", urls, error);
        return nil;
    }
    return urls;
}

-(void)loadLocalPlaces
{
    NSMutableArray *places = [self.places mutableCopy];
    if (!places)
    {
        places = [NSMutableArray array];
    }
    
    NSMutableArray *placesToRemove = [NSMutableArray array];
    
    for (VPLPlace *place in places)
    {
        if (![place.baseURL checkResourceIsReachableAndReturnError:NULL])
        {
            [placesToRemove addObject:place];
        }
    }
    [places removeObjectsInArray:placesToRemove];

    NSArray *placesURLs = [self URLsForLocalPlaces];
    for (NSURL *url in placesURLs)
    {
        VPLPlace *place = [self placeWithBaseURL:url];
        if (place)
        {
            [places addObject:place];
        }
    }
    
    self.places = [places copy];
}

-(void)updateRemotePlacesListWithCompletion:(VPLPlaceManagerCompletion)completion
{
    NSDate *lastUpdate = [NSUserDefaults standardUserDefaults].lastBundlePlaceListUpdate;
    if (lastUpdate)
    {
        if (([[NSDate date] timeIntervalSinceDate:lastUpdate] < kVPLBunldePlaceListUpdateInterval) &&
            ([VPLPlaceInfo numberOfPlacesInContext:[NSManagedObjectContext sharedContext]] > 0))
        {
            DLog(@"bundle list updated recently, skipping for now");
            completion(NO);
            return;
        }
    }
    VPLPlaceManagerCompletion complectionBlock = [completion copy];
    [[self.querySession dataTaskWithURL:[NSURL URLWithString:kVPLRemotePlacesURL]
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          if ((data) && (!error))
                          {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self parsePlaceInfo:data completion:complectionBlock];
                              });
                          }
                          else
                          {
                              DLog(@"response = %@, error = %@", response, error);
                              if (complectionBlock)
                              {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      complectionBlock(NO);
                                  });
                              }
                          }
                      }] resume];
}

-(void)parsePlaceInfo:(NSData*)data completion:(VPLPlaceManagerCompletion)completion
{
    NSError * __autoreleasing error;
    NSDictionary *placeInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ((error) || (!placeInfo) || (![placeInfo isKindOfClass:[NSDictionary class]]))
    {
        DLog(@"error = %@, info = %@", error, placeInfo);
        if (completion)
        {
            completion(NO);
        }
        return;
    }
    
    NSString *version = placeInfo[kVPLVersionKey];
    if ([version compare:kVPLSupportedVersion options:NSNumericSearch] == NSOrderedDescending)
    {
        DLog(@"version is higher than supported %@ > %@", version, kVPLSupportedVersion);
        if (completion)
        {
            completion(NO);
        }
        return;
    }
    
    NSArray *places = placeInfo[kVPLPlacesKey];
    for (NSDictionary *infoDict in places)
    {
        VPLPlaceInfo *info = [VPLPlaceInfo placeInfoWithUID:infoDict[kVPLIdentifierKey]
                                                  inContext:[NSManagedObjectContext sharedContext]];
        info.remoteRevision = infoDict[kVPLRevisionKey];
        info.archiveLink = infoDict[kVPLArchiveURLKey];
        info.reportedSize = [infoDict[kVPLFileSizeKey] longLongValue];
        NSArray *texts = infoDict[kVPLTextsKey];
        for (NSDictionary *textDict in texts)
        {
            VPLPlaceText *text = [VPLPlaceText textWithLanguage:textDict[kVPLLanguageKey]
                                                   forPlaceInfo:info];
            text.title = textDict[kVPLTitleKey];
            text.details = textDict[kVPLDetailsKey];
        }
    }
    DLog(@"updated bundle place list");
    [[NSManagedObjectContext sharedContext] save];
    [NSUserDefaults standardUserDefaults].lastBundlePlaceListUpdate = [NSDate date];
    
    if (completion)
    {
        completion(YES);
    }
}

-(void)downloadPlaceAtURL:(NSURL*)url
               identifier:(NSString*)identifier
               completion:(VPLPlaceManagerCompletion)completion
{
    VPLPlaceManagerCompletion completionBlock = [completion copy];
    
    [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        BOOL taskFound = NO;
        for (NSURLSessionDownloadTask *task in downloadTasks)
        {
            if ([task.taskDescription isEqualToString:identifier])
            {
                taskFound = YES;
                break;
            }
        }
        if (!taskFound)
        {
            self.completionHanlders[identifier] = completionBlock;
            NSURLSessionDownloadTask *task = [self.downloadSession downloadTaskWithURL:url];
//        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
//            
//                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
//                if ((location) && (!error) && (httpResponse.statusCode == kVPLHTTPStatusOk))
//                {
//                    BOOL success = ([self unpackPlaceArchiveAtURL:location
//                                                   deleteOriginal:YES] != nil);
//                    if (completionBlock)
//                    {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            completionBlock(success);
//                        });
//                    }
//                }
//                else
//                {
//                    DLog(@"response = %@, error = %@", response, error);
//                    if (completionBlock)
//                    {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            completionBlock(NO);
//                        });
//                    }
//                }
//            }];
            task.taskDescription = identifier;
            
            [task resume];
        }
    }];
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error)
    {
        DLog(@"failed with error %@", error);
        VPLPlaceManagerCompletion completionBlock = self.completionHanlders[task.taskDescription];
        [self.completionHanlders removeObjectForKey:task.taskDescription];
        VPLPlaceInfo *info = [VPLPlaceInfo existingPlaceInfoWithUID:task.taskDescription
                                                          inContext:[NSManagedObjectContext sharedContext]];
        info.totalSize = 0;
        info.downloadedSize = 0;
        [[NSManagedObjectContext sharedContext] save];
        if (completionBlock)
        {
            completionBlock(NO);
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:VPLPlaceDownloadedNotification
                                                                object:self];
        }
    }
}

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    VPLPlaceManagerCompletion completionBlock = self.completionHanlders[downloadTask.taskDescription];
    [self.completionHanlders removeObjectForKey:downloadTask.taskDescription];
    
    DLog(@"task %@->%@", downloadTask.taskDescription, location);
    if (location)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError * __autoreleasing error;
    
        NSString *tempLocation = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        NSURL *tempURL = [NSURL fileURLWithPath:tempLocation];
        [fm moveItemAtURL:location toURL:tempURL error:&error];
        DLog(@"moved to %@, error = %@", tempURL, error);
        dispatch_async(self.unpackQueue, ^{
            BOOL success = ([self unpackPlaceArchiveAtURL:tempURL
                                           deleteOriginal:YES] != nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock)
                {
                    completionBlock(success);
                }
                else
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:VPLPlaceDownloadedNotification
                                                                        object:self];
                }
                VPLPlaceInfo *info = [VPLPlaceInfo existingPlaceInfoWithUID:downloadTask.taskDescription
                                                                  inContext:[NSManagedObjectContext sharedContext]];
                info.totalSize = 0;
                info.downloadedSize = 0;
                [[NSManagedObjectContext sharedContext] save];
            });
        });
    }
    else
    {
        if (completionBlock)
        {
            completionBlock(NO);
        }
    }
}

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    DLog(@"task %@->%lld of %lld", downloadTask.taskDescription, fileOffset, expectedTotalBytes);
    VPLPlaceInfo *info = [VPLPlaceInfo existingPlaceInfoWithUID:downloadTask.taskDescription
                                                      inContext:[NSManagedObjectContext sharedContext]];
    info.totalSize = expectedTotalBytes;
    info.downloadedSize = fileOffset;
    [[NSManagedObjectContext sharedContext] save];
}

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
     didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    DLog(@"task %@->%lld, %lld of %lld", downloadTask.taskDescription, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    VPLPlaceInfo *info = [VPLPlaceInfo existingPlaceInfoWithUID:downloadTask.taskDescription
                                                      inContext:[NSManagedObjectContext sharedContext]];
    info.totalSize = totalBytesExpectedToWrite;
    info.downloadedSize = totalBytesWritten;
    [[NSManagedObjectContext sharedContext] save];
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    DLog(@"completing background processing for %@", session);
    if (self.sessionCompletion)
    {
        self.sessionCompletion();
    }
    self.sessionCompletion = nil;
}

@end
