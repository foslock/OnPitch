//
//  OPSongPlayer.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/25/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSongPlayer.h"
#import "OPSong.h"
#import "OPTimer.h"
#import "OPNote.h"
#import "OPSamplePlayer.h"
#import <AudioToolbox/AudioToolbox.h>

#define SONG_INTERVAL_LENGTH (1.0f/60.0f)

@interface OPSongPlayer ()

@property (strong) OPSong* song;
@property (strong) OPTimer* currentTimer;
@property (strong) NSMutableArray* playedNotes;
@property (assign) MusicTimeStamp songPosition;

- (void)timerPinged:(OPTimer*)timer;

@end

@implementation OPSongPlayer

- (id)initWithSong:(OPSong*)song {
    self = [super init];
    if (self) {
        self.song = song;
        self.playedNotes = [NSMutableArray array];
        self.tempo = song.tempo;
        _isPlaying = NO;
        _isPaused = NO;
    }
    return self;
}

- (void)play {
    if (!self.isPlaying) {
        _isPlaying = YES;
        _isPaused = NO;
        self.currentTimer = [OPTimer scheduledTimerWithTimeInterval:SONG_INTERVAL_LENGTH
                                                             target:self
                                                           selector:@selector(timerPinged:)
                                                           userInfo:nil];
    }
}

- (void)pause {
    if (self.isPlaying) {
        _isPaused = YES;
        _isPlaying = NO;
    }
}

- (void)stop {
    _isPaused = NO;
    _isPlaying = NO;
    self.songPosition = 0.0f;
    [self.currentTimer stopFiring];
    [self.playedNotes removeAllObjects];
    self.currentTimer = nil;
}

#pragma mark - Timer Callback

- (void)timerPinged:(OPTimer*)timer {
    if (!self.isPlaying) {
        return;
    }
    
    // BRUTE FORCE - This could and probably should be optimized
    // Check all notes and play those that need to be
    int count = self.song.notes.count;
    for (int i = 0; i < count; i++) {
        OPNote* note = [self.song.notes objectAtIndex:i];
        if (note.timestamp <= self.songPosition &&
            ![self.playedNotes containsObject:note]) {
            [self.playedNotes addObject:note];
            [[OPSamplePlayer sharedPlayer] playNoteWithIndex:note.noteIndex withLength:note.length];
            if (self.playedNotes.count >= self.song.notes.count) {
                [timer stopFiring];
            }
        }
    }
    self.songPosition += SONG_INTERVAL_LENGTH;
}

@end
