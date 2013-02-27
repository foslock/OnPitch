//
//  OPMicInput.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPMicInput.h"
#import "OPAudioHandler.h"
#import "OPFFT.h"

#define FREQUENCY_LOWER_RANGE 40.0f
#define FREQUENCY_UPPER_RANGE 8000.0f
#define FREQUENCY_GRANULARITY 5.0f

#define TIMER_INTERVAL_PING 0.05f

@interface OPMicInput ()

@property (assign) AudioHandler* audioHandler;
@property (assign) BOOL isCurrentlyListeningToMicInput;
@property (assign) float currentHeardPitch;
@property (assign) float currentMaxAmplitude;

@property (strong) NSTimer* queryTimer;

- (void)queryTimerPinged:(NSTimer*)timer;

@end

@implementation OPMicInput

+ (OPMicInput*)sharedInput {
    static OPMicInput* _one = nil;
    @synchronized(self) {
        if (_one == nil) {
            _one = [[OPMicInput alloc] init];
        }
    }
    return _one;
}

- (id)init {
    self = [super init];
    if (self) {
        self.audioHandler = new AudioHandler();
        self.queryTimer = nil;
        self.muted = YES;
        self.currentHeardPitch = 0.0f;
        self.currentMaxAmplitude = 0.0f;
    }
    return self;
}

- (void)dealloc {
    if (self.audioHandler) {
        delete self.audioHandler;
        self.audioHandler = NULL;
    }
}

- (void)setMuted:(BOOL)muted {
    self.audioHandler->mute = muted;
}

- (BOOL)isMuted {
    return self.audioHandler->mute;
}

- (void)queryTimerPinged:(NSTimer*)timer {
    self.audioHandler->RefreshFFTData();
    float currentAmp = FLT_MIN;
    for (int f = FREQUENCY_LOWER_RANGE; f < FREQUENCY_UPPER_RANGE; f += FREQUENCY_GRANULARITY) {
        float thisAmp = self.audioHandler->AmplitudeOfFrequency(f);
        if (thisAmp > currentAmp) {
            currentAmp = thisAmp;
            self.currentHeardPitch = f;
            self.currentMaxAmplitude = thisAmp;
        }
    }
}

- (void)startAnalyzingMicInput {
    if (!self.isCurrentlyListeningToMicInput) {
        self.isCurrentlyListeningToMicInput = YES;
        // Start FFT'ing!
        self.queryTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL_PING
                                                           target:self
                                                         selector:@selector(queryTimerPinged:)
                                                         userInfo:nil
                                                          repeats:YES];
        
    }
}

- (void)stopAnalyzingMicInput {
    if (self.isCurrentlyListeningToMicInput) {
        self.isCurrentlyListeningToMicInput = NO;
        // Stop it all!
        [self.queryTimer invalidate];
        self.queryTimer = nil;
        self.currentHeardPitch = 0.0f;
        self.currentMaxAmplitude = 0.0f;
    }
}

- (float)currentLoudestPitchMicHears {
    return self.currentHeardPitch;
}

- (float)currentVolumeMicHears {
    return self.currentMaxAmplitude;
}

@end
