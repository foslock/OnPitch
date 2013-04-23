//
//  OPMetronome.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPMetronome.h"
#import "OPTimer.h"
#import <AVFoundation/AVFoundation.h>

@interface OPMetronome ()

@property (strong) OPTimer* timer;
@property (strong) AVAudioPlayer* clickPlayer;

@end

@implementation OPMetronome

+ (OPMetronome*)sharedMetronome {
    static OPMetronome* _one = nil;
    @synchronized(self) {
        if (_one == nil) {
            _one = [[OPMetronome alloc] init];
        }
    }
    return _one;
}

- (id)init {
    self = [super init];
    if (self) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"];
        self.clickPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
        [self.clickPlayer prepareToPlay];
        self.metronomeVolume = 1.0f;
        self.beatsPerMinute = 120.0f; // Gets timer set up!
    }
    return self;
}

- (void)setBeatsPerMinute:(float)beatsPerMinute {
    BOOL timerRunning = self.timer.isRunning;
    if (self.timer) { [self.timer stopFiring]; }
    self.timer = [OPTimer timerWithTimeInterval:(60.0f) / beatsPerMinute
                                         target:self
                                       selector:@selector(timerHasFired:)
                                       userInfo:nil];
    if (timerRunning) {
        [self.timer startFiring];
    }
}

- (void)setMetronomeVolume:(float)metronomeVolume {
    if (self.clickPlayer) {
        [self.clickPlayer setVolume:metronomeVolume];
    }
}

- (void)startMetronome {
    if (!self.isRunning) {
        _isRunning = YES;
        [self.timer startFiring];
    }
}

- (void)stopMetronome {
    if (self.isRunning) {
        _isRunning = NO;
        [self.timer stopFiring];
    }
}

#pragma mark - OPTimer

- (void)timerHasFired:(OPTimer *)timer {
    if (self.clickPlayer) {
        // NSLog(@"Click");
        [self.clickPlayer play];
    }
}

@end
