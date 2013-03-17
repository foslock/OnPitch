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
#define NOTE_HEIGHT 20.0f
#define NOTE_LENGTH_SCALE_FACTOR 100.0f
#define REST_HEIGHT 20.0f
#define STAFF_LINEWIDTH 3.0f
#define NUMBER_OF_STAFF_LINES 5
#define STAFF_LINE_SPACING 70.0f
#define NOTE_SPACING STAFF_LINE_SPACING


@interface OPSongView ()

@property (strong) OPSong *song;
@property (strong) UIPanGestureRecognizer* panGesture;
@property (strong) UIPinchGestureRecognizer* pinchGesture;
@property (assign) CGFloat panStartOffset;
@property (assign) CGFloat pinchStartScale;

- (void)initMe;
- (void)viewDidPan:(UIPanGestureRecognizer*)pan;
- (void)viewDidPinch:(UIPinchGestureRecognizer*)pinch;
- (NSInteger)staffLineForNoteIndex:(NSInteger)noteIndex withLowestOctave:(NSInteger)lowestOctave;
- (CGFloat)heightForStaffLine:(NSInteger)staffLine;

@end

@implementation OPSongView

- (void)initMe {
    [self setOpaque:NO];
    self.backgroundColor = [UIColor clearColor];
    self.contentWidth = self.bounds.size.width;
    _contentScale = 1.0f;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
    [self addGestureRecognizer:self.panGesture];
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPinch:)];
    [self addGestureRecognizer:self.pinchGesture];
    
    NSString *testPath = [[NSBundle mainBundle] pathForResource:@"testmidi1" ofType:@"mid"];
    OPSong *s = [[OPSong alloc] initWithMIDIFile:testPath];
    self.song = s;
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
        _isPanning = YES;
    }
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        self.panStartOffset = 0.0f;
        _isPanning = NO;
    }
    
    [self.feedbackView setNeedsDisplay];
    [self setNeedsDisplay];
}

- (void)viewDidPinch:(UIPinchGestureRecognizer*)pinch {
    if (pinch.state == UIGestureRecognizerStateBegan) {
        self.pinchStartScale = self.contentScale;
        _isPinching = YES;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = pinch.scale;
        CGFloat newScale = self.pinchStartScale * (scale / 1.2f); // Scale down the scale factor (ITS SO META!)
        _contentScale = CLAMP(newScale, MIN_HORIZONTAL_SCALE, MAX_HORIZONTAL_SCALE);
        // self.drawingOffset *= self.contentScale;
        _isPinching = YES;
    }
    if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled) {
        self.pinchStartScale = 1.0f;
        _isPinching = NO;
    }
    
    [self.feedbackView setNeedsDisplay];
    [self setNeedsDisplay];
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
    
    // Draw staff
    CGContextSetLineWidth(context, STAFF_LINEWIDTH);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    for (NSInteger i=0; i<NUMBER_OF_STAFF_LINES; i++) {
        CGContextMoveToPoint(context, 0.0f, self.bounds.size.height/2.0f+(i-2)*STAFF_LINE_SPACING);
        CGContextAddLineToPoint(context, self.bounds.size.width,
                                self.bounds.size.height/2.0f+(i-NUMBER_OF_STAFF_LINES/2)*STAFF_LINE_SPACING);
        CGContextStrokePath(context);
    }
    
    // Compute x values
    /*
    NSMutableArray *xvals = [[NSMutableArray alloc] init];
    CGFloat totalLength = 0;
    CGFloat currentX;
    for (NSInteger i=0; i<self.song.notes.count; i++)
    {
        OPNote *n = [self.song.notes objectAtIndex:i];
        currentX = totalLength * NOTE_LENGTH_SCALE_FACTOR + n.timestamp;
        totalLength += n.length;
        [xvals addObject:[NSNumber numberWithInteger:currentX]];
    }
     */
    
    // Draw notes
    for (NSInteger i=0; i<self.song.notes.count; i++)
    {
        OPNote *n = [self.song.notes objectAtIndex:i];
        CGFloat width = (CGFloat)n.length * NOTE_LENGTH_SCALE_FACTOR;
        CGFloat x = ((CGFloat)n.timestamp + i*NOTE_LENGTH_SCALE_FACTOR) - self.drawingOffset;
        //CGFloat x = (CGFloat)[(NSNumber *)[xvals objectAtIndex:i] floatValue];
        CGFloat y = REST_HEIGHT;
        if (n.nameIndex != kNoteNameNone) {
            NSInteger staffLine = [self staffLineForNoteIndex:n.noteIndex withLowestOctave:self.song.lowestOctave];
            NSLog(@"staffLine = %i", staffLine);
            y = [self heightForStaffLine:staffLine];
        }
        
        CGContextSetFillColorWithColor(context, [self colorForNote:n]);
        CGRect noteRect = CGRectMake(x, y, width, NOTE_HEIGHT);
        CGContextFillRect(context, noteRect);
        CGContextStrokePath(context);
    }
    
}

- (CGColorRef)colorForNote:(OPNote *)note
{
    // Maybe change the color depending on the note?
    
    //CGFloat i = (CGFloat)note.noteIndex / (CGFloat)MAX_NOTE_INDEX;
    //UIColor *color1 = [UIColor colorWithHue:i saturation:i brightness:i alpha:1.0f];
    //UIColor *color2 = [UIColor colorWithRed:i green:i blue:i alpha:1.0f];
    
    return [UIColor whiteColor].CGColor;
}

- (NSInteger)staffLineForNoteIndex:(NSInteger)noteIndex withLowestOctave:(NSInteger)lowestOctave
{
    NSInteger staffLine = noteIndex % NUMBER_OF_NOTES - 2;// + (noteIndex/NUMBER_OF_NOTES-lowestOctave)*NUMBER_OF_NOTES;
    //NSLog(@"offset = %d", (noteIndex/NUMBER_OF_NOTES-lowestOctave)*NUMBER_OF_NOTES);
    return staffLine;
}

- (CGFloat)heightForStaffLine:(NSInteger)staffLine
{
    CGFloat height = self.bounds.size.height/2.0f + staffLine * NOTE_SPACING - NOTE_HEIGHT/2.0f;
    return height;
}

@end
