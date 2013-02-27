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
#define FREQUENCY_GRANULARITY 0.5f

#define TIMER_INTERVAL_PING 0.05f

@interface OPMicInput ()

@property (assign) AudioHandler* audioHandler;
@property (assign) BOOL isCurrentlyListeningToMicInput;
@property (assign) float currentHeardPitch;
@property (assign) float currentMaxAmplitude;

@property (strong) NSOperationQueue* operationQueue;

- (void)queryTimerPinged;

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
        self.currentHeardPitch = 0.0f;
        self.currentMaxAmplitude = 0.0f;
        self.operationQueue = [[NSOperationQueue alloc] init];
        
        self.muted = YES;
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

- (void)queryTimerPinged {
    self.audioHandler->RefreshFFTData();
    float currentAmp = FLT_MIN;
    for (float f = FREQUENCY_LOWER_RANGE; f < FREQUENCY_UPPER_RANGE; f += FREQUENCY_GRANULARITY) {
        float thisAmp = self.audioHandler->AmplitudeOfFrequency(f);
        if (thisAmp > currentAmp) {
            currentAmp = thisAmp;
            self.currentHeardPitch = f;
            self.currentMaxAmplitude = thisAmp;
            // NSLog(@"f: %.2f a: %.2f", f, thisAmp);
        }
    }
    // Add this operation back on the queue to reanalyze the pitch
    [self.operationQueue addOperationWithBlock:^{
        [self queryTimerPinged];
    }];
}

- (void)startAnalyzingMicInput {
    if (!self.isCurrentlyListeningToMicInput) {
        self.isCurrentlyListeningToMicInput = YES;
        // Start FFT'ing!
        [self.operationQueue addOperationWithBlock:^{
            [self queryTimerPinged];
        }];
    }
}

- (void)stopAnalyzingMicInput {
    if (self.isCurrentlyListeningToMicInput) {
        self.isCurrentlyListeningToMicInput = NO;
        // Stop it all!
        [self.operationQueue cancelAllOperations];
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
