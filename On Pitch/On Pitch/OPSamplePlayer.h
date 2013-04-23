//
//  OPSamplePlayer.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/25/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

// Singleton for playing sounds (loaded from sample wavs?)

#define SAMPLE_SOUND_TYPE_COUNT 3

enum kSampleSoundIndex {
    kSampleSoundPiano,
    kSampleSoundVoice,
    kSampleSoundTrumpet,
};

#import <Foundation/Foundation.h>

@interface OPSamplePlayer : NSObject

@property (assign, nonatomic) enum kSampleSoundIndex sampleSound;

+ (OPSamplePlayer*)sharedPlayer;

- (void)playNoteWithIndex:(NSInteger)index withLength:(NSTimeInterval)length;

@end
