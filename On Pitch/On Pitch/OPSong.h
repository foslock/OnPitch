//
//  OPSong.h
//  On Pitch
//
//  Created by Dan Fortunato on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPSong : NSObject

@property (strong) NSArray *notes;
@property (strong) NSString *timeSig;
@property NSInteger lowestOctave;
@property (assign) NSUInteger tempo;
@property (assign) NSUInteger octaveRange;

- (id)initWithMIDIFile:(NSString *)pathToFile;

@end
