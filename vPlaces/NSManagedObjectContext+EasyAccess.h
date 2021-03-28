//
//  NSManagedObjectContext+EasyContextAccess.h
//  GDC Book
//
//  Created by Danis Tazetdinov on 10.01.12.
//  Copyright (c) 2012 Fujitsu Russia GDC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (EasyAccess)

+ (NSManagedObjectContext*)sharedContext;

+ (NSManagedObjectContext *)context;
+ (NSManagedObjectContext *)contextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

- (void)save;

-(NSArray *)executeFetchRequest:(NSFetchRequest *)request;
-(NSUInteger)countForFetchRequest:(NSFetchRequest *)request;

@end
