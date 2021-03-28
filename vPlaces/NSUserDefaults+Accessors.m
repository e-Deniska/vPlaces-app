//
//  NSUserDefaults+Accessors.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "NSUserDefaults+Accessors.h"
#import "DPHue.h"

#define KEY_HUENAME       @"hueName"
#define KEY_APPUSERNAME   @"appUserName"
#define KEY_LAMPNUMBERS   @"lampNumbers"
#define KEY_BUNDLEOFFERED @"bundlePlacesOffered"
#define KEY_ALLOWCELLULAR @"allowCellularAccess"
#define KEY_LASTUPDATE    @"lastBundleListUpdate"

@implementation NSUserDefaults (Accessors)

-(NSString *)hueName
{
    return [self objectForKey:KEY_HUENAME];
}

-(void)setHueName:(NSString *)hueName
{
    [self setObject:hueName forKey:KEY_HUENAME];
    [self synchronize];
}

-(NSString *)appUsername
{
    NSString *appUsername = [self objectForKey:KEY_APPUSERNAME];
    if (!appUsername)
    {
        appUsername = [DPHue generateUsername];
        [self setObject:appUsername forKey:KEY_APPUSERNAME];
        [self synchronize];
    }
    return appUsername;
}

-(NSArray *)lampNumbers
{
    return [self objectForKey:KEY_LAMPNUMBERS];
}

-(void)setLampNumbers:(NSArray *)lampNumbers
{
    if (lampNumbers)
    {
        [self setObject:lampNumbers forKey:KEY_LAMPNUMBERS];
    }
    else
    {
        [self removeObjectForKey:KEY_LAMPNUMBERS];
    }
    [self synchronize];
}

-(BOOL)bundlePlacesOffered
{
    return [self boolForKey:KEY_BUNDLEOFFERED];
}

-(void)setBundlePlacesOffered:(BOOL)bundlePlacesOffered
{
    [self setBool:bundlePlacesOffered forKey:KEY_BUNDLEOFFERED];
    [self synchronize];
}

-(NSDate *)lastBundlePlaceListUpdate
{
    return [self objectForKey:KEY_LASTUPDATE];
}

-(void)setLastBundlePlaceListUpdate:(NSDate *)lastBundlePlaceListUpdate
{
    if (lastBundlePlaceListUpdate)
    {
        [self setObject:lastBundlePlaceListUpdate forKey:KEY_LASTUPDATE];
    }
    else
    {
        [self removeObjectForKey:KEY_LASTUPDATE];
    }
    [self synchronize];
}

-(BOOL)allowCellularAccess
{
    return [self boolForKey:KEY_ALLOWCELLULAR];
}

-(void)setAllowCellularAccess:(BOOL)allowCellularAccess
{
    [self setBool:allowCellularAccess forKey:KEY_ALLOWCELLULAR];
    [self synchronize];
}

@end
