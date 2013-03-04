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
        OPMIDIParser *p = [OPMIDIParser parser];
        self.song = [p parseFileWithPath:pathToFile];
    }
    return self;
}

@end
