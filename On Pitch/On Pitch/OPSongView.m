//
//  OPSongView.m
//  On Pitch
//
//  Created by Dan Fortunato on 3/11/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPSongView.h"
#import "OPNote.h"
#import "OPFeedbackView.h"

// Change these 'til it looks purty
#define NOTE_HEIGHT 10.0f
#define NOTE_SPACING 10.0f
#define REST_HEIGHT 20.0f
#define STAFF_LINEWIDTH 5.0f
#define NUMBER_OF_STAFF_LINES 5
#define LINE_SPACING 10.0f

@interface OPSongView ()

@property (strong) OPSong *song;
@property (strong) UIPanGestureRecognizer* panGesture;
@property (assign) CGFloat panStartOffset;

- (void)initMe;
- (void)viewDidPan:(UIPanGestureRecognizer*)pan;

@end

@implementation OPSongView

- (void)initMe {
    self.contentWidth = self.bounds.size.width;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
    [self addGestureRecognizer:self.panGesture];
}

- (id)initWithSong:(OPSong *)s
{
    self = [super init];
    if (self) {
        self.song = s;
        [self initMe];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initMe];
    }
    return self;
}

#pragma mark - Pan Gesture Callback

- (void)viewDidPan:(UIPanGestureRecognizer*)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.panStartOffset = self.drawingOffset;
        _isPanning = YES;
    }
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint offset = [pan translationInView:self];
        float max = MAX(self.contentWidth - self.bounds.size.width, 0.0f);
        self.drawingOffset = CLAMP(self.panStartOffset - offset.x, 0.0f, max);
        NSLog(@"%f", self.drawingOffset);
        _isPanning = YES;
    }
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        self.panStartOffset = 0.0f;
        _isPanning = NO;
    }
    
    [self setNeedsDisplay];
    [self.feedbackView setNeedsDisplay];
}

#pragma mark - Drawing
/*
- (void)drawRect:(CGRect)rect {
    // Gets the context of this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set some state vars for lines
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // Clear the space
    CGContextClearRect(context, rect);
    
    // Draw staff
    CGContextSetLineWidth(context, STAFF_LINEWIDTH);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    for (NSInteger i=0; i<NUMBER_OF_STAFF_LINES; i++) {
        CGContextMoveToPoint(context, 0.0f, i * LINE_SPACING);
        CGContextAddLineToPoint(context, 0.0f, i * LINE_SPACING);
        CGContextStrokePath(context);
    }
    
    // Draw notes
    for (NSInteger i=0; i<self.song.notes.count; i++)
    {
        OPNote *n = [self.song.notes objectAtIndex:i];
        CGFloat width = (CGFloat)n.length;
        CGFloat x = (CGFloat)n.timestamp;
        CGFloat y = REST_HEIGHT;
        if (n.nameIndex != kNoteNameNone) {
            y = n.noteIndex * NOTE_SPACING;
        }
        
        // Maybe change the color depending on the note?
        CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
        CGRect noteRect = CGRectMake(x, y, width, NOTE_HEIGHT);
        CGContextFillRect(context, noteRect);
        CGContextStrokePath(context);
    }
}

- (CGColorRef)colorForNote:(OPNote *)note
{
    NSInteger i = note.noteIndex;
    UIColor *color = [UIColor colorWithRed:(CGFloat)i green:(CGFloat)i blue:(CGFloat)i alpha:(CGFloat)i];
    return color.CGColor;
}
*/

@end
