//
//  OPNote.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define NUMBER_OF_NOTES 12
#define NUMBER_OF_OCTAVES 8
#define MAX_NOTE_INDEX ((NUMBER_OF_NOTES * NUMBER_OF_OCTAVES) - 1)

// The 's' denotes a sharp
enum kNoteNameIndex {
    kNoteNameNone = -1, // REST
    kNoteNameA = 0,
    kNoteNameAs,
    kNoteNameB,
    kNoteNameC,
    kNoteNameCs,
    kNoteNameD,
    kNoteNameDs,
    kNoteNameE,
    kNoteNameF,
    kNoteNameFs,
    kNoteNameG,
    kNoteNameGs,
};

enum kNoteOctaveIndex {
    kNoteOctaveNone = -1, // Octaveless note
    kNoteOctaveOne = 0,
    kNoteOctaveTwo,
    kNoteOctaveThree,
    kNoteOctaveFour,
    kNoteOctaveFive,
    kNoteOctaveSix,
    kNoteOctaveSeven,
    kNoteOctaveEight,
};

extern NSString* const kNoteNames[NUMBER_OF_NOTES];
extern NSString* const kNoteAlternateNames[NUMBER_OF_NOTES];
extern NSString* const kNoteOctaveSuffixes[NUMBER_OF_OCTAVES];

@interface OPNote : NSObject

//
@property (readonly) NSInteger noteIndex;
@property (readonly) enum kNoteNameIndex nameIndex;
@property (readonly) enum kNoteOctaveIndex octaveIndex;

@property (assign) NSTimeInterval length;
@property (assign) MusicTimeStamp timestamp;

// Use one of the following convienence methods to create notes (do not use [[OPNote alloc] init])
+ (OPNote*)noteFromStaffIndex:(NSInteger)index;
+ (OPNote*)noteFromNameIndex:(enum kNoteNameIndex)name withOctaveIndex:(enum kNoteOctaveIndex)octave;

- (float)exactFrequencyFromNote;

- (BOOL)isNoteAccidental;

- (NSString*)staffNameForNote; // Uses sharps
- (NSString*)alternateStaffNameForNote; // Uses flats
- (NSString*)staffNameForNoteWithoutOctave; // No octave

@end
