//
//  OPAudioHandler.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/14/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SAMPLES_PER_SECOND 44100.0f

@interface OPAudioHandler : NSObject

@property (assign, getter = isMuted) BOOL muted;
@property (assign, getter = isRunning) BOOL running;

// For a peek into the FFT buffer
@property (readonly) int32_t* fftDataBuffer;
@property (readonly) NSUInteger fftLength;
@property (readonly) float currentFFTMaxValue; // Magnitude value
@property (readonly) NSUInteger currentFFTMaxIndex; // The index into the FFT that seems to be around the largest value
@property (readonly) float currentMaxVolume; // The maximum magnitude (of 0.0 to 1.0) that the most recent sample contained

- (void)refreshFFTData;

- (float)amplitudeOfFrequency:(float)freq;

- (float)frequencyFromIndex:(float)index;
- (float)indexFromFrequency:(float)frequency;

@end
