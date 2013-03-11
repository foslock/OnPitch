//
//  OPMetronome.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPMetronome : NSObject

@property (assign, nonatomic) float beatsPerMinute;
@property (assign, nonatomic) float metronomeVolume;
@property (readonly) BOOL isRunning;

+ (OPMetronome*)sharedMetronome;

- (void)startMetronome;
- (void)stopMetronome;

@end
