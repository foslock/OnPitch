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
    kNoteOctaveNone = -1,
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

@property (assign) NSInteger noteIndex;
@property (assign) enum kNoteNameIndex nameIndex;
@property (assign) enum kNoteOctaveIndex octaveIndex;

@property (assign) NSTimeInterval length;
@property (assign) MusicTimeStamp timestamp;

+ (OPNote*)noteFromStaffIndex:(NSInteger)index;

- (float)exactFrequencyFromNote;

- (NSString*)staffNameForNote; // Uses sharps
- (NSString*)alternateStaffNameForNote; // Uses flats

@end
