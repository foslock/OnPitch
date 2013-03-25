//
//  OPSamplePlayer.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/25/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSamplePlayer.h"
#import "OPNote.h"
#import <AVFoundation/AVFoundation.h>

NSString* const kSampleSoundFilePrefix[SAMPLE_SOUND_TYPE_COUNT] = {
    @"Piano_",
    @"Voice_",
    @"Trumpet_",
};

@interface OPSamplePlayer ()

@property (strong) NSArray* sampleArray; // Array of AVAudioPlayers
@property (strong) AVAudioPlayer* currentPlayingSample;

- (void)setupSampleArray;

@end

@implementation OPSamplePlayer

- (id)init {
    self = [super init];
    if (self) {
        self.sampleSound = kSampleSoundPiano;
    }
    return self;
}

+ (OPSamplePlayer*)sharedPlayer {
    static OPSamplePlayer* _one = nil;
    @synchronized(self) {
        if (_one == nil) {
            _one = [[OPSamplePlayer alloc] init];
        }
    }
    return _one;
}

- (void)setupSampleArray {
    self.currentPlayingSample = nil;
    NSString* filenamePrefix = kSampleSoundFilePrefix[self.sampleSound];
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:NUMBER_OF_NOTES * NUMBER_OF_OCTAVES];
    for (int o = 0; o < NUMBER_OF_OCTAVES; o++) {
        for (int n = 0; n < NUMBER_OF_NOTES; n++) {
            NSString* filename = [filenamePrefix stringByAppendingFormat:@"%02i%02i", o, n]; // format ex. "Piano_xxyy" => "Piano_0208"
            NSString* path = [[NSBundle mainBundle] pathForResource:filename ofType:@"wav"];
            if (path) {
                NSURL* url = [NSURL fileURLWithPath:path];
                AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                [player prepareToPlay];
                [array addObject:player];
            }
        }
    }
    self.sampleArray = array;
}

- (void)setSampleSound:(enum kSampleSoundIndex)sampleSound {
    _sampleSound = CLAMP(sampleSound, 0, SAMPLE_SOUND_TYPE_COUNT - 1);
    [self setupSampleArray];
}

- (void)playNoteWithIndex:(NSInteger)index withLength:(NSTimeInterval)length {
    if (index < [self.sampleArray count]) {
        if (self.currentPlayingSample) {
            [self.currentPlayingSample stop];
            self.currentPlayingSample = nil;
        }
        AVAudioPlayer* sample = [self.sampleArray objectAtIndex:index];
        self.currentPlayingSample = sample;
        [sample play];
        // Handle length here too
    }
}

@end
