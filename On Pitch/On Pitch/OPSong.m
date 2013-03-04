//
//  OPSong.m
//  On Pitch
//
//  Created by Dan Fortunato on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSong.h"

@implementation OPSong

-(id) initWithMIDIFile:(NSData *)midiData
{
    self = [super init];
    if (self)
    {
        // Parse the MIDI file into an array of OPNotes
    }
    return self;
}

@end
