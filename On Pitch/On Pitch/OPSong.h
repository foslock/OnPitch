//
//  OPSong.h
//  On Pitch
//
//  Created by Dan Fortunato on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPSong : NSObject
{
    NSArray *song;
}

-(id) initWithMIDIFile:(NSData *)midiData;

@end
