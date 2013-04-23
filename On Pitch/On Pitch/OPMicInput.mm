//
//  OPMicInput.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPMicInput.h"
#import "OPAudioHandler.h"

#define FREQUENCY_CHECK_RANGE 10.0f
#define FREQUENCY_GRANULARITY 1.0f

#define TIMER_INTERVAL_PING 0.05f // Seconds

@interface OPMicInput ()

@property (strong) OPAudioHandler* audioHandler;
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
        self.audioHandler = [[OPAudioHandler alloc] init];
        self.currentHeardPitch = 0.0f;
        self.currentMaxAmplitude = 0.0f;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.muted = YES;
    }
    return self;
}

- (void)setMuted:(BOOL)muted {
    self.audioHandler.muted = muted;
}

- (BOOL)isMuted {
    return self.audioHandler.isMuted;
}

- (void)queryTimerPinged {
    [self.audioHandler refreshFFTData];
    float currentAmp = FLT_MIN;
    int maxIndex = [self.audioHandler currentFFTMaxIndex];
    int startIndex = maxIndex - (FREQUENCY_CHECK_RANGE/2);
    float startFreq = [self.audioHandler frequencyFromIndex:startIndex];
    for (float f = startFreq; f < startFreq + FREQUENCY_CHECK_RANGE; f += FREQUENCY_GRANULARITY) {
        float thisAmp = [self.audioHandler amplitudeOfFrequency:f];
        if (thisAmp > currentAmp) {
            currentAmp = thisAmp;
            self.currentHeardPitch = f;
            self.currentMaxAmplitude = thisAmp;
            // printf("start: %.2f f: %.2f a: %.2f\n", startFreq, f, thisAmp);
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
    return self.audioHandler.currentMaxVolume;
}

@end
