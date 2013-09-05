//
//  NSManagedObjectContext_Extensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 5/27/09.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "NSManagedObjectContext_Extensions.h"

#import <objc/runtime.h>

#import "CDebuggingManagedObjectContext.h"

@implementation NSManagedObjectContext (NSManagedObjectContext_Extensions)

#if DEBUG == 1
static void *kDebugNameKey;

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (\"%@\", inserted: %lld, updated: %lld, deleted: %lld)", [super description], self.debugNamePath, (int64_t)[self insertedObjects].count, (int64_t)[self updatedObjects].count, (int64_t)[self deletedObjects].count]);
    }

- (NSString *)debugName
    {
    return(objc_getAssociatedObject(self, kDebugNameKey));
    }
    
- (void)setDebugName:(NSString *)debugName
    {
    objc_setAssociatedObject(self, kDebugNameKey, debugName, OBJC_ASSOCIATION_RETAIN);
    }

- (NSString *)debugNamePath
    {
    if (self.parentContext == NULL)
        {
        return(self.debugName);
        }
    else
        {
        return([NSString stringWithFormat:@"%@.%@", self.parentContext.debugNamePath, self.debugName]);
        }
    }

#endif

- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct
    {
    NSManagedObjectContext *theChildManagedObjectContext = [[[self class] alloc] initWithConcurrencyType:ct];
    theChildManagedObjectContext.parentContext = self;
    return(theChildManagedObjectContext);
    }

- (NSManagedObjectContext *)newChildManagedObjectContext
    {
	return([self newChildManagedObjectContextWithConcurrencyType:self.concurrencyType]);
    }

- (NSUInteger)countOfObjectsOfEntityForName:(NSString *)inEntityName predicate:(NSPredicate *)inPredicate error:(NSError **)outError
{
NSEntityDescription *theEntityDescription = [NSEntityDescription entityForName:inEntityName inManagedObjectContext:self];
NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
[theFetchRequest setEntity:theEntityDescription];
if (inPredicate)
	[theFetchRequest setPredicate:inPredicate];
NSUInteger theCount = [self countForFetchRequest:theFetchRequest error:outError];
return(theCount);
}

- (NSArray *)fetchObjectsOfEntityForName:(NSString *)inEntityName predicate:(NSPredicate *)inPredicate sortDescriptors:(NSArray *)inSortDescriptors error:(NSError **)outError
    {
    NSEntityDescription *theEntityDescription = [NSEntityDescription entityForName:inEntityName inManagedObjectContext:self];
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    theFetchRequest.entity = theEntityDescription;
    theFetchRequest.sortDescriptors = inSortDescriptors;
    theFetchRequest.predicate = inPredicate;
    NSArray *theObjects = [self executeFetchRequest:theFetchRequest error:outError];
    return(theObjects);
    }

- (NSArray *)fetchObjectsOfEntityForName:(NSString *)inEntityName predicate:(NSPredicate *)inPredicate error:(NSError **)outError
    {
    return([self fetchObjectsOfEntityForName:inEntityName predicate:inPredicate sortDescriptors:NULL error:outError]);
    }

#pragma mark -

- (id)fetchObjectOfEntityForName:(NSString *)inEntityName predicate:(NSPredicate *)inPredicate sortDescriptors:(NSArray *)inSortDescriptors error:(NSError **)outError
    {
    NSEntityDescription *theEntityDescription = [NSEntityDescription entityForName:inEntityName inManagedObjectContext:self];
    NSFetchRequest *theFetchRequest = [[NSFetchRequest alloc] init];
    theFetchRequest.entity = theEntityDescription;
    theFetchRequest.sortDescriptors = inSortDescriptors;
    theFetchRequest.predicate = inPredicate;
    theFetchRequest.fetchLimit = 1;
    NSArray *theObjects = [self executeFetchRequest:theFetchRequest error:outError];
    id theObject = [theObjects lastObject];
    return(theObject);
    }

- (id)fetchObjectOfEntityForName:(NSString *)inEntityName predicate:(NSPredicate *)inPredicate error:(NSError **)outError
    {
    return([self fetchObjectOfEntityForName:inEntityName predicate:inPredicate sortDescriptors:NULL error:outError]);
    }

#pragma mark -

- (id)fetchObjectOfEntityForName:(NSString *)inEntityName properties:(NSDictionary *)inProperties createIfNotFound:(BOOL)inCreateIfNotFound wasCreated:(BOOL *)outWasCreated error:(NSError **)outError
    {
    id theObject = NULL;
    
    NSMutableArray *theSubpredicates = [NSMutableArray array];
    
    [inProperties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [theSubpredicates addObject:[NSPredicate predicateWithFormat:@"%K == %@", key, obj]];
        }];

    NSPredicate *thePredicate = NULL;
    if (theSubpredicates.count == 1)
        {
        thePredicate = [theSubpredicates lastObject];
        }
    else
        {
        thePredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:theSubpredicates];
        }
    
    NSArray *theObjects = [self fetchObjectsOfEntityForName:inEntityName predicate:thePredicate error:outError];
    BOOL theWasCreatedFlag = NO;
    if (theObjects)
        {
        const NSUInteger theCount = theObjects.count;
        if (theCount == 0)
            {
            if (inCreateIfNotFound == YES)
                {
                theObject = [NSEntityDescription insertNewObjectForEntityForName:inEntityName inManagedObjectContext:self];
                if (theObject)
                    {
                    theWasCreatedFlag = YES;
                    [inProperties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        [theObject setValue:obj forKey:key];
                        }];
                    }
                }
            }
        else if (theCount == 1)
            {
            theObject = [theObjects lastObject];
            }
        else
            {
            if (outError)
                {
                NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat:@"Expected 1 object (of type %@) but got %lld instead.", inEntityName, (int64_t)theObjects.count], NSLocalizedDescriptionKey,
                    NULL];
                
                *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:theUserInfo];
                }
            }
        }
    if (theObject && outWasCreated)
        *outWasCreated = theWasCreatedFlag;
        
    return(theObject);
    }

- (id)fetchObjectOfEntityForName:(NSString *)inEntityName properties:(NSDictionary *)inProperties error:(NSError **)outError;
	{
	return([self fetchObjectOfEntityForName:inEntityName properties:inProperties createIfNotFound:NO wasCreated:NULL error:outError]);
	}

#pragma mark -

- (void)assertHasNoChanges
    {
    Assert_([self hasChanges] == NO, @"Managed object context has changes.");
    }

- (void)logChanges
    {
    if ([self hasChanges] == NO)
        {
		NSLog(@"MOC (%@) is clean.", self);
        }
    else
        {
		NSLog(@"MOC (%@) has unsaved changes.", self);
		
		if ([self insertedObjects].count > 0)
			{
			NSLog(@"insertedObjects: %@", [[self insertedObjects] valueForKey:@"objectID"]);
			}

		if ([self updatedObjects].count > 0)
			{
			NSLog(@"updatedObjects: %@", [[self updatedObjects] valueForKey:@"objectID"]);
			}

		if ([self deletedObjects].count > 0)
			{
			NSLog(@"deletedObjects: %@", [[self deletedObjects] valueForKey:@"objectID"]);
			}
        }
    }

- (BOOL)performBlockAndSave:(void (^)(void))block error:(NSError **)outError
    {
    AssertParameter_(block);
    
    if ([self hasChanges])
        {
        [self logChanges];
        }
    if ([self hasChanges] && [self isKindOfClass:[CDebuggingManagedObjectContext class]])
        {
        NSArray *theCallstacks = ((CDebuggingManagedObjectContext *)self).callStacksForDirtyPerformBlocks;
        if (theCallstacks == NULL)
            {
            NSLog(@"Dirty MOC found but callstacks empty.");
            }
        else
            {
            NSLog(@"%@", theCallstacks);
            }
        }
        
    __block BOOL theResult = NO;
    [self performBlockAndWait:^{
        @try
            {
            block();
            
            // We only save _if_ we have changes (to prevent notifications from firing)
            if ([self hasChanges] == YES)
                {
//                NSLog(@"Saving %@", self);
                theResult = [self save:outError];
                }
            }
        @catch (NSException * e)
            {
            NSLog(@"EXCEPTION: %@", e);
            
            if ([self hasChanges])
                {
                [self rollback];
                }
            
            if (outError)
                {
                NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat:@"Exception thrown while performing transaction: %@", e], NSLocalizedDescriptionKey,
                    e, @"exception",
                    NULL];
                *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:theUserInfo];
                }
            }
        }];
    
    return(theResult);
    }

- (void)performBlockAndSave:(void (^)(void))block;
    {
    [self performBlockAndSave:block error:NULL];
    }

- (id)objectWithURL:(NSURL *)inURL
    {
    NSManagedObjectID *theObjectID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:inURL];
    NSManagedObject *theObject = [self objectWithID:theObjectID];
    return(theObject);   
    }

- (id)insertNewEntityForName:(NSString *)name
	{
    return([NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:self]);
	}

@end
