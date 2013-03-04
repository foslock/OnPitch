//
//  OPMIDIParser.m
//  On Pitch
//
//  Created by Dan Fortunato on 3/3/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPMIDIParser.h"

@interface OPMIDIParser ()

@property (assign) NSString *filename;

@end

@implementation OPMIDIParser

- (id)init;
{
    self = [super init];
    if (self)
    {
        self.filename = @"";
    }
    
    return self;
}


// Parsing code adapted from SO and Apple
// http://stackoverflow.com/questions/4666935/midi-file-parsing
// http://developer.apple.com/library/mac/#samplecode/PlaySequence/Introduction/Intro.html#//apple_ref/doc/uid/DTS40008652

- (void)parseFileWithPath:(NSString *)path
{
    self.filename = [path lastPathComponent];
    NSLog(@"Parsing %@", self.filename);
    
    MusicSequence sequence;
    NewMusicSequence(&sequence);
    
    NSLog(@"%@",[NSURL fileURLWithPath:path]);
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    MusicSequenceFileLoad(sequence, url, 0, 0);
    
    MusicTrack track = NULL;
    UInt32 tracks;
    MusicSequenceGetTrackCount(sequence, &tracks);
    
    for (NSInteger i=0; i<tracks; i++)
    {
        MusicSequenceGetIndTrack(sequence, i, &track);
        
        // Create an interator
        MusicEventIterator iterator = NULL;
        NewMusicEventIterator(track, &iterator);
        MusicTimeStamp timestamp = 0;
        MusicEventType eventType = 0;
        
        const void *eventData = NULL;
        UInt32 eventDataSize = 0;
        
        Boolean hasNext;
        MusicEventIteratorHasNextEvent(iterator, &hasNext);
        
        // A variable to store note messages
        MIDINoteMessage *midiNoteMessage;
        
        // Iterate over events
        while (hasNext)
        {
            // See if there are any more events
            MusicEventIteratorHasNextEvent(iterator, &hasNext);
            
            // Copy the event data into the variables we prepared earlier
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
            
            // Process Midi Note messages
            if(eventType==kMusicEventType_MIDINoteMessage) {
                // Cast the midi event data as a midi note message
                midiNoteMessage = (MIDINoteMessage*) eventData;
                
            }
            
            NSLog(@"Note: %i, Duration: %f", midiNoteMessage->note, midiNoteMessage->duration);
            
            MusicEventIteratorNextEvent(iterator);
        }
    }
}

@end
