//
//  OPMIDIParser.h
//  On Pitch
//
//  Created by Dan Fortunato on 3/3/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreMIDI/CoreMIDI.h>

@interface OPMIDIParser : NSObject

- (void)parseFileWithPath:(NSString *)file;

@end
