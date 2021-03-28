//
//  NSManagedObjectContext+EasyContextAccess.m
//  GDC Book
//
//  Created by Danis Tazetdinov on 10.01.12.
//  Copyright (c) 2012 Fujitsu Russia GDC. All rights reserved.
//

#import "NSManagedObjectContext+EasyAccess.h"

@implementation NSManagedObjectContext (EasyAccess)

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    static dispatch_once_t onceToken;
    static NSPersistentStoreCoordinator * psc;
    dispatch_once(&onceToken, ^
    {
        
        NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                   inDomains:NSUserDomainMask] lastObject]
                           URLByAppendingPathComponent:@"data.sqlite"];
        
        NSError * __autoreleasing error;
        NSManagedObjectModel * managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
        psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:@{ NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                                NSInferMappingModelAutomaticallyOption: @(YES) }
                                       error:&error])
        {
            DLog(@"Persistent store not opened %@, %@", error, error.userInfo);
        }
    });
    
    return psc;
}

+ (NSManagedObjectContext*)sharedContext
{
    static dispatch_once_t onceToken;
    static NSManagedObjectContext *_sharedContext;
    dispatch_once(&onceToken, ^{
        _sharedContext = [self contextWithConcurrencyType:NSMainQueueConcurrencyType];
        [[NSNotificationCenter defaultCenter] addObserver:_sharedContext
                                                 selector:@selector(mergeChangesToSharedContext:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    });
    return _sharedContext;
}

-(void)mergeChangesToSharedContext:(NSNotification*)notification
{
    NSManagedObjectContext *savingContext = notification.object;
    if ((savingContext.persistentStoreCoordinator == self.persistentStoreCoordinator) &&
        (self != savingContext) && (notification.userInfo))
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //DLog(@"merging changes to sharedContext...");
            [self mergeChangesFromContextDidSaveNotification:notification];
            [self processPendingChanges];
        });
    }
}


+ (NSManagedObjectContext *)context
{
    return [self contextWithConcurrencyType:NSConfinementConcurrencyType];
}

+ (NSManagedObjectContext *)contextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    NSManagedObjectContext *context;
    if (coordinator)
    {
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
        context.persistentStoreCoordinator = coordinator;
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }
    
    context.undoManager = nil;
    
    return context;    
}

- (void)save
{
    NSError * __autoreleasing error;
    if ([self hasChanges] && ![self save:&error])
    {
        DLog(@"Fatal error saving object context: %@, %@", error, error.userInfo);
    } 
}

-(NSArray *)executeFetchRequest:(NSFetchRequest *)request
{
    NSError * __autoreleasing error;
    NSArray *results = [self executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fatal error executing fetch request: %@, %@", error, error.userInfo);
    }
    return results;
}

-(NSUInteger)countForFetchRequest:(NSFetchRequest *)request
{
    NSError * __autoreleasing error;
    NSUInteger count = [self countForFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fatal error counting for fetch request: %@, %@", error, error.userInfo);
    }
    return count;
}

@end
