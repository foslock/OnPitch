//
//  OPNoteTranslator.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPNoteTranslator.h"
#import "OPNote.h"

NSInteger const kA4NoteIndex = 36;
float const kA4NoteFrequency = 440.0f;

@interface OPNoteTranslator ()

@property (strong) NSMutableArray* notesFrequencyArray;

- (void)initArray;

@end

@implementation OPNoteTranslator

+ (OPNoteTranslator*)translator {
    static OPNoteTranslator* _one = nil;
    @synchronized(self) {
        if (_one == nil) {
            _one = [[OPNoteTranslator alloc] init];
        }
    }
    return _one;
}

- (void)initArray {
    // Use the middle A as a reference
    int semitoneDistance = -kA4NoteIndex;
    for (int o = 0; o < NUMBER_OF_OCTAVES; o++) {
        for (int n = 0; n < NUMBER_OF_NOTES; n++) {
            // Starts on A1, which is 36 away from middle
            float thisFreq = kA4NoteFrequency * powf(2, semitoneDistance / 12.0f);
            [self.notesFrequencyArray addObject:[NSNumber numberWithFloat:thisFreq]];
            semitoneDistance++;
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.notesFrequencyArray = [NSMutableArray array];
        [self initArray];
    }
    return self;
}

- (float)frequencyFromNoteStaffIndex:(NSInteger)index {
    NSNumber* num = [self.notesFrequencyArray objectAtIndex:index];
    return [num floatValue];
}

- (NSInteger)noteStaffIndexForFrequency:(float)freq {
    NSInteger dist = 12 * log2f(freq / kA4NoteFrequency);
    dist += kA4NoteIndex;
    dist = MIN(MAX(0, dist), NUMBER_OF_NOTES * NUMBER_OF_OCTAVES - 1);
    return dist;
}

@end
