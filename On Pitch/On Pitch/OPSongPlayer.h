//
//  OPSongPlayer.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/25/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OPSong;

@interface OPSongPlayer : NSObject

@property (assign, nonatomic) float tempo; // BPM, default 120
@property (assign, nonatomic) float volume; // 0.0 to 1.0

@property (readonly) OPSong* song;
@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isPaused;

- (id)initWithSong:(OPSong*)song;

- (void)play;
- (void)pause;
- (void)stop; // Returns track to beginning

@end
