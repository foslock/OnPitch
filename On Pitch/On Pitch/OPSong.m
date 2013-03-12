//
//  OPSong.m
//  On Pitch
//
//  Created by Dan Fortunato on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSong.h"
#import "OPMIDIParser.h"

@implementation OPSong

-(id) initWithMIDIFile:(NSString *)pathToFile
{
    self = [super init];
    if (self)
    {
        // Parse the MIDI file into an array of OPNotes
        NSDictionary *d = [OPMIDIParser parseFileWithPath:pathToFile];
        self.notes = [d objectForKey:@"notes"];
        self.tempo = (NSUInteger)[(NSString *)[d objectForKey:@"tempo"] intValue];
        self.timeSig = [d objectForKey:@"timeSig"];
        self.octaveRange = [d objectForKey:@"octaveRange"];
    }
    return self;
}

@end
