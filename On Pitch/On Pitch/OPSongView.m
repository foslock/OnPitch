//
//  OPSongView.m
//  On Pitch
//
//  Created by Dan Fortunato on 3/11/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSongView.h"
#import "OPNote.h"

// Change these 'til it looks purty
#define NOTE_HEIGHT 10.0f
#define NOTE_SPACING 10.0f
#define REST_HEIGHT 20.0f

@interface OPSongView ()

@property (strong) OPSong *song;

@end

@implementation OPSongView

- (id)initWithSong:(OPSong *)s
{
    self = [super init];
    if (self) {
        self.song = s;
    }
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    // Gets the context of this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set some state vars for lines
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // Clear the space
    CGContextClearRect(context, rect);
    
    for (NSInteger i=0; i<self.song.notes.count; i++)
    {
        OPNote *n = [self.song.notes objectAtIndex:i];
        CGFloat width = (CGFloat)n.length;
        CGFloat x = 
        CGFloat y = REST_HEIGHT;
        if (n.nameIndex != kNoteNameNone) {
            CGFloat y = n.noteIndex * NOTE_SPACING;
        }
        
        CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
        CGRect noteRect = CGRectMake(x, y, width, NOTE_HEIGHT);
        CGContextFillRect(context, noteRect)
        CGContextStrokePath(currentContext);

}

@end
