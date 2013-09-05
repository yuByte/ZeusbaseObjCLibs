//
//  CNetworkManager.m
//  TouchCode
//
//  Created by Jonathan Wight on 9/15/11.
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
//  THIS SOFTWARE IS PROVIDED BY 2011 TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 2011 TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of 2011 toxicsoftware.com.

#import "CNetworkManager.h"

#import "Asserts.h"
#import "CTypedData.h"

#if TARGET_OS_IPHONE == 1
#import "CNetworkActivityManager.h"
#endif /* TARGET_OS_IPHONE == 1 */

@interface CNetworkManager ()
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
#if TARGET_OS_IPHONE == 1
@property (readwrite, nonatomic, strong) CNetworkActivityManager *activityManager;
#endif /* TARGET_OS_IPHONE == 1 */
@end

@implementation CNetworkManager

@synthesize operationQueue;
#if TARGET_OS_IPHONE == 1
@synthesize activityManager;
#endif /* TARGET_OS_IPHONE == 1 */
@synthesize currentRequests;

static Class gSingletonClass = NULL;
static CNetworkManager *gSharedInstance = NULL;

+ (void)setSharedInstanceClass:(Class)inClass
    {
    NSParameterAssert(gSingletonClass == NULL);
    NSParameterAssert(inClass != NULL);
    //
    gSingletonClass = inClass;
    }

+ (CNetworkManager *)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        if (gSingletonClass == NULL)
            {
            gSingletonClass = self;
            }
        gSharedInstance = [[gSingletonClass alloc] init];
        NSParameterAssert([gSharedInstance isKindOfClass:[self class]]);
        });
    return(gSharedInstance);
    }

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        operationQueue = [NSOperationQueue mainQueue];
#if TARGET_OS_IPHONE == 1
        activityManager = [[CNetworkActivityManager alloc] init];
#endif /* TARGET_OS_IPHONE == 1 */
        currentRequests = [[NSMutableSet alloc] init];
        }
    return self;
    }

- (void)sendRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
    {
    [self sendRequest:request shouldBackground:NO completionHandler:handler];
    }

- (void)sendRequest:(NSURLRequest *)request shouldBackground:(BOOL)inShouldBackground completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
    {
#if TARGET_OS_IPHONE == 1
    [self.activityManager addNetworkActivity];
#endif /* TARGET_OS_IPHONE == 1 */
    [self.currentRequests addObject:request];

    #if TARGET_OS_IPHONE == 1
    UIBackgroundTaskIdentifier theBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    if (inShouldBackground)
        {
        theBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
        }
    #endif /* TARGET_OS_IPHONE == 1 */

    __weak CNetworkManager *_self = self;
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

        BOOL theHandledFlag = NO;

        if (error == NULL)
            {
            if ([response isKindOfClass:[NSHTTPURLResponse class]])
                {
                NSHTTPURLResponse *theHTTPResponse = AssertCast_([NSHTTPURLResponse class], response);

                if (theHTTPResponse.statusCode < 200 || theHTTPResponse.statusCode >= 400)
                    {
                    NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
                    if (request != NULL)
                        {
                        [theUserInfo setObject:request forKey:@"request"];
                        }
                    if (response != NULL)
                        {
                        [theUserInfo setObject:response forKey:@"response"];
                        }
                    if (data != NULL)
                        {
                        NSString *theContentType = [[theHTTPResponse allHeaderFields] objectForKey:@"Content-Type"];

                        CTypedData *theTypedData = [[CTypedData alloc] initWithContentType:theContentType data:data];
                        [theUserInfo setObject:theTypedData forKey:@"typedData"];
                        }
                    [theUserInfo setObject:response forKey:@"response"];


                    NSError *theError = [NSError errorWithDomain:@"HTTP_DOMAIN" code:theHTTPResponse.statusCode userInfo:theUserInfo];

                    handler(NULL, NULL, theError);
                    theHandledFlag = YES;
                    }
                }
            }

        if (theHandledFlag == NO)
            {
            handler(response, data, error);
            }



        #if TARGET_OS_IPHONE == 1
        if (inShouldBackground)
            {
            [[UIApplication sharedApplication] endBackgroundTask:theBackgroundTaskIdentifier];
            }
        #endif /* TARGET_OS_IPHONE == 1 */

#if TARGET_OS_IPHONE == 1
        [_self.activityManager removeNetworkActivity];
#endif /* TARGET_OS_IPHONE == 1 */
        [_self.currentRequests removeObject:request];

//        double delayInSeconds = 30.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (dispatch_time_t)(delayInSeconds * NSEC_PER_SEC));
//        LogDebug_(@"Started");
//        dispatch_after(popTime, dispatch_get_main_queue(),^{
//            theBlock();
//            LogDebug_(@"Finished");
//            });

        }];

    }


@end
