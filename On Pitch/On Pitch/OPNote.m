//
//  OPNote.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPNote.h"
#import "OPNoteTranslator.h"

NSString* const kNoteNames[NUMBER_OF_NOTES] = {
    @"A",
    @"A#",
    @"B",
    @"C",
    @"C#",
    @"D",
    @"D#",
    @"E",
    @"F",
    @"F#",
    @"G",
    @"G#",
};

NSString* const kNoteAlternateNames[NUMBER_OF_NOTES] = {
    @"A",
    @"Bb",
    @"B",
    @"C",
    @"Db",
    @"D",
    @"Eb",
    @"E",
    @"F",
    @"Gb",
    @"G",
    @"Ab",
};

NSString* const kNoteOctaveSuffixes[NUMBER_OF_OCTAVES] = {
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
};

@implementation OPNote

- (id)init {
    self = [super init];
    if (self) {
        self.noteIndex = 0;
        self.nameIndex = kNoteNameNone;
        self.octaveIndex = kNoteOctaveNone;
    }
    return self;
}

+ (OPNote*)noteFromStaffIndex:(NSInteger)index {
    OPNote* note = [[OPNote alloc] init];
    note.noteIndex = CLAMP(index, 0, MAX_NOTE_INDEX);
    note.nameIndex = CLAMP(note.noteIndex % NUMBER_OF_NOTES, 0, NUMBER_OF_NOTES);
    note.octaveIndex = CLAMP(note.noteIndex / NUMBER_OF_NOTES, 0, NUMBER_OF_OCTAVES);
    return note;
}

- (float)exactFrequencyFromNote {
    float freq = [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:self.noteIndex];
    return freq;
}

- (NSString*)staffNameForNote {
    if (self.nameIndex == kNoteNameNone ||
        self.octaveIndex == kNoteOctaveNone) {
        return @"N/A";
    }
    NSString* name = [NSString stringWithFormat:@"%@%@", kNoteNames[self.nameIndex], kNoteOctaveSuffixes[self.octaveIndex]];
    return name;
}

- (NSString*)alternateStaffNameForNote {
    if (self.nameIndex == kNoteNameNone ||
        self.octaveIndex == kNoteOctaveNone) {
        return @"N/A";
    }
    NSString* name = [NSString stringWithFormat:@"%@%@", kNoteAlternateNames[self.nameIndex], kNoteOctaveSuffixes[self.octaveIndex]];
    return name;
}

@end
