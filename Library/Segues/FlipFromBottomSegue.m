//
//  FlipFromBottomSegue.m
//  ZeusCustomSegues
//
//  Created by Haralambos Yokos on 2/4/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "FlipFromBottomSegue.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

@implementation FlipFromBottomSegue

-(id)initWithIdentifier:(NSString *)identifier
                 source:(UIViewController *)source
            destination:(UIViewController *)destination {
    
    if(self = [super initWithIdentifier:identifier
                                 source:source
                            destination:destination]) {
        
        NSLog(@"Custom initialization");
    }
    
    return self;
}

-(void)perform {
    
    __block UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    __block UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    
    [UIView transitionWithView:sourceViewController.navigationController.view
                      duration:.5
                       options:UIViewAnimationOptionTransitionFlipFromBottom
                    animations:^{
                        [sourceViewController.navigationController pushViewController:destinationController
                                                                             animated:NO];
                    }
                    completion:^(BOOL finished) {
                        NSLog(@"Transition Completed");
                    }];
}

@end