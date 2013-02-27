//
//  OPNoteTranslator.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//


//
// This class is for finding the frequency of a staff note.
// The indecies start at 0 (A1) and go up to 95 (G#8).
// The frequency is calculated based around 440Hz (see implementation).
//


#import <Foundation/Foundation.h>

extern NSInteger const kA4NoteIndex;
extern float const kA4NoteFrequency;

@interface OPNoteTranslator : NSObject

+ (OPNoteTranslator*)translator;

// Notes start a A1 and go for 8 total octaves
- (float)frequencyFromNoteStaffIndex:(NSInteger)index;
- (NSInteger)noteStaffIndexForFrequency:(float)freq;

@end
