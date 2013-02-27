//
//  OPMicInput.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPMicInput : NSObject

+ (OPMicInput*)sharedInput;

- (void)setMuted:(BOOL)muted;
- (BOOL)isMuted;

- (void)startAnalyzingMicInput;
- (void)stopAnalyzingMicInput;

- (float)currentLoudestPitchMicHears; // in Hz
- (float)currentVolumeMicHears; // From 0.0 to 1.0, general average of all freqs

@end
