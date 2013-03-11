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

@interface OPMetronome () <OPTimerDelegate>

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
        self.timer = [[OPTimer alloc] init];
        self.timer.delegate = self;
        self.metronomeVolume = 1.0f;
        self.beatsPerMinute = 120.0f;
    }
    return self;
}

- (void)setBeatsPerMinute:(float)beatsPerMinute {
    if (self.timer) {
        float nanoseconds = (1000.0f * 1000.0f * 1000.0f * 60.0f) / beatsPerMinute;
        self.timer.intervalInNanoSeconds = nanoseconds;
    }
}

- (void)setMetronomeVolume:(float)metronomeVolume {
    if (self.clickPlayer) {
        [self.clickPlayer setVolume:metronomeVolume];
    }
}

- (void)startMetronome {
    [self.timer startFiring];
}

- (void)stopMetronome {
    [self.timer stopFiring];
}

#pragma mark - OPTimer

- (void)timerHasFired:(OPTimer *)timer {
    if (self.clickPlayer) {
        [self.clickPlayer setCurrentTime:0.0f];
        [self.clickPlayer play];
    }
}

@end
