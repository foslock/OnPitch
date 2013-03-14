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

@interface OPNote ()

@property (assign) NSInteger noteIndex;
@property (assign) enum kNoteNameIndex nameIndex;
@property (assign) enum kNoteOctaveIndex octaveIndex;

@end

@implementation OPNote

+ (OPNote*)noteFromStaffIndex:(NSInteger)index {
    OPNote* note = [[OPNote alloc] init];
    note.noteIndex = CLAMP(index, 0, MAX_NOTE_INDEX);
    note.nameIndex = CLAMP(note.noteIndex % NUMBER_OF_NOTES, 0, NUMBER_OF_NOTES - 1);
    note.octaveIndex = CLAMP(note.noteIndex / NUMBER_OF_NOTES, 0, NUMBER_OF_OCTAVES - 1);
    return note;
}

+ (OPNote*)noteFromNameIndex:(enum kNoteNameIndex)name withOctaveIndex:(enum kNoteOctaveIndex)octave {
    NSInteger noteIndex = (octave * NUMBER_OF_NOTES) + name;
    return [OPNote noteFromStaffIndex:noteIndex];
}

- (float)exactFrequencyFromNote {
    return [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:self.noteIndex];
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

- (NSString*)staffNameForNoteWithoutOctave {
    if (self.nameIndex == kNoteNameNone ||
        self.octaveIndex == kNoteOctaveNone) {
        return @"N/A";
    }
    NSString* name = kNoteNames[self.nameIndex];
    return name;
}

@end
