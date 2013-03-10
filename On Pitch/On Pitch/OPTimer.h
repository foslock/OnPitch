//
//  OPTimer.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

// Forward declaration of protocol
@protocol OPTimerDelegate;

@interface OPTimer : NSObject

@property (weak) id<OPTimerDelegate> delegate;
@property (assign) NSInteger intervalInNanoSeconds;

- (void)startFiring;
- (void)stopFiring;

@end

@protocol OPTimerDelegate <NSObject>

// Will be called on a background thread, DO NOT DO 'UI' OPERATIONS HERE (sounds are OK though)
- (void)timerHasFired:(OPTimer*)timer;

@end