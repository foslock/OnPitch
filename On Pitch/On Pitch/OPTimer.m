//
//  OPTimer.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPTimer.h"
#import <mach/mach_time.h>

#define NANO_SECOND_SCALE (1000.0f * 1000.0f * 1000.0f)

@interface OPTimer ()

@property (assign) NSInteger intervalInNanoSeconds;
@property (assign) mach_timebase_info_data_t timeInfo;
@property (strong) NSThread* backgroundThread;

- (void)loopMethod;

@end

@implementation OPTimer

+ (OPTimer*)timerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo {
    OPTimer* timer = [[OPTimer alloc] init];
    timer.target = target;
    timer.selector = selector;
    timer.intervalInNanoSeconds = interval * NANO_SECOND_SCALE;
    timer.userInfo = userInfo;
    return timer;
}

+ (OPTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo {
    OPTimer* timer = [OPTimer timerWithTimeInterval:interval target:target selector:selector userInfo:userInfo];
    [timer startFiring];
    return timer;
}

- (id)init {
    self = [super init];
    if (self) {
        mach_timebase_info(&_timeInfo);
        self.intervalInNanoSeconds = 0;
        self.backgroundThread = nil;
    }
    return self;
}

- (void)startFiring {
    if (!_isRunning) {
        _isRunning = YES;
        [self.backgroundThread cancel];
        self.backgroundThread = nil;
        // Set the current start time
        self.backgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(loopMethod) object:nil];
        // [self.backgroundThread setThreadPriority:1.0];
        [self.backgroundThread start];
    }
}

- (void)stopFiring {
    if (_isRunning) {
        _isRunning = NO;
        [self.backgroundThread cancel];
        self.backgroundThread = nil;
    }
}

- (NSTimeInterval)interval {
    return (double)self.intervalInNanoSeconds / NANO_SECOND_SCALE;
}

- (void)setUserInfo:(id)userInfo {
    _userInfo = userInfo;
    if (!userInfo) {
        _userInfo = self;
    }
}

// Callback method on different thread

- (void)loopMethod {
    uint64_t currentTime = 0;
    uint64_t currentStartTime = mach_absolute_time();
    currentStartTime *= _timeInfo.numer;
    currentStartTime /= _timeInfo.denom;
    uint64_t interval = self.intervalInNanoSeconds;
    uint64_t counter = 0;
    
    @autoreleasepool {
        while (interval > 0) {
            if (!_isRunning) {
                [NSThread exit];
                return;
            }
            
            // Do stuff on background thread
            currentTime = mach_absolute_time();
            currentTime *= _timeInfo.numer;
            currentTime /= _timeInfo.denom;
            
            if (currentTime >= currentStartTime + (interval * counter)) {
                counter++;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.target performSelector:self.selector withObject:self.userInfo];
#pragma clang diagnostic pop
            }
        }
    }
}

@end
