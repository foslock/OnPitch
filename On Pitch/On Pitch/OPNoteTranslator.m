//
//  OPNoteTranslator.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/27/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPNoteTranslator.h"

NSString* const kNoteNames[7] = {
    @"A",
    @"B",
    @"C",
    @"D",
    @"E",
    @"F",
    @"G",
};

NSString* const kNoteOctaveSuffixes[8] = {
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
};

@implementation OPNoteTranslator

+ (NSString*)noteNameFromClosestFrequency:(float)frequency {
    
}

+ (float)exactFrequencyFromNoteName:(NSString*)name {
    
}

@end
