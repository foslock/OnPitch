//
//  OPTimer.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPTimer.h"
#import <mach/mach_time.h>

@interface OPTimer ()

@property (assign) mach_timebase_info_data_t timeInfo;
@property (strong) NSThread* backgroundThread;
@property (assign) BOOL shouldExit;

- (void)loopMethod;

@end

@implementation OPTimer

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
    [self stopFiring];
    self.backgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(loopMethod) object:nil];
    [self.backgroundThread start];
}

- (void)stopFiring {
    [self.backgroundThread cancel];
    self.backgroundThread = nil;
}

// Callback method on different thread

- (void)loopMethod {
    uint64_t nextTime = 0;
    uint64_t currentTime = 0;
    while (![self.backgroundThread isCancelled] && self.intervalInNanoSeconds > 0) {
        // Do stuff on background thread
        currentTime = mach_absolute_time();
        currentTime *= _timeInfo.numer;
        currentTime /= _timeInfo.denom;
        
        if (currentTime >= nextTime) {
            nextTime = currentTime + self.intervalInNanoSeconds;
            if ([self.delegate respondsToSelector:@selector(timerHasFired:)]) {
                [self.delegate timerHasFired:self];
            }
        }
    }
}

@end
