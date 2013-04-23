//
//  OPTimer.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPTimer : NSObject

@property (readonly) BOOL isRunning;
@property (readonly) NSTimeInterval interval;

@property (weak) id target;
@property (assign) SEL selector;
@property (weak, nonatomic) id userInfo;

// Creates a timer that is not scheduled
+ (OPTimer*)timerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo;

// Creates an auto scheduled timer (no need to call 'startFiring')
+ (OPTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo;

- (void)startFiring;
- (void)stopFiring;

@end