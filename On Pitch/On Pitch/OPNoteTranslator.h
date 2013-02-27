//
//  OPNoteTranslator.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

enum kNoteNameIndex {
    kNoteNameA,
    kNoteNameB,
    kNoteNameC,
    kNoteNameD,
    kNoteNameE,
    kNoteNameF,
    kNoteNameG,
};

enum kNoteOctaveIndex {
    kNoteOctaveOne,
    kNoteOctaveTwo,
    kNoteOctaveThree,
    kNoteOctaveFour,
    kNoteOctaveFive,
    kNoteOctaveSix,
    kNoteOctaveSeven,
    kNoteOctaveEight,
};

extern NSString* const kNoteNames[7];
extern NSString* const kNoteOctaveSuffixes[8];

@class OPNote;

@interface OPNoteTranslator : NSObject

+ (OPNote*)noteFromClosestFrequency:(float)frequency;
+ (float)exactFrequencyFromNote:(OPNote*)note;

@end
