//
//  OPAppDelegate.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CLAMP(X, A, B) (MIN(B, MAX(A, X)))

@interface OPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (OPAppDelegate*)currentDelegate;
+ (NSString*)documentsPath;

@end