//
//  OPMicInput.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

//
// This class is fairly self explanatory, it is user friendly
// and uses the uglier C++ class to do its dirty work.
//

#import <Foundation/Foundation.h>

@interface OPMicInput : NSObject

+ (OPMicInput*)sharedInput;

- (void)setMuted:(BOOL)muted;
- (BOOL)isMuted;

- (void)startAnalyzingMicInput;
- (void)stopAnalyzingMicInput;

- (float)currentLoudestPitchMicHears; // in Hz


// STILL IMPLEMENTING, RETURNS A RELATIVE VOLUME NOW WITHOUT A REFERENCE SCALE
- (float)currentVolumeMicHears;
// Eventually will be on 0.0 to 1.0 scale

@end
