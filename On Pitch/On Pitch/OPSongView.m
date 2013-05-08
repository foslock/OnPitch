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
#import "OPSongPlayer.h"

// Change these 'til it looks purty
#define NOTE_HEIGHT 30.0f
#define NOTE_LENGTH_SCALE_FACTOR 60.0f
#define REST_HEIGHT 20.0f
#define STAFF_LINEWIDTH 3.0f
#define NUMBER_OF_STAFF_LINES 7
#define STAFF_LINE_SPACING 50.0f
#define NOTE_CORNER_RADIUS 8.0f
#define NOTE_SPACING (STAFF_LINE_SPACING)

@interface OPSongView ()

@property (strong) OPSong *song;
@property (strong) UIPanGestureRecognizer* panGesture;
@property (strong) UIPinchGestureRecognizer* pinchGesture;
@property (assign) CGFloat panStartOffset;
@property (assign) CGFloat pinchStartScale;

@property (assign) CGFloat tapeHeadLocation;

// Testing
@property (strong) OPSongPlayer* player;

- (void)initMe;
- (void)viewDidPan:(UIPanGestureRecognizer*)pan;
- (void)viewDidPinch:(UIPinchGestureRecognizer*)pinch;
- (CGFloat)staffLineForNote:(OPNote*)note withLowestOctave:(NSInteger)lowestOctave;
- (CGFloat)heightForStaffLine:(CGFloat)staffLine;

@end

@implementation OPSongView

- (void)initMe {
    [self setOpaque:NO];
    /*
    NSString* path = [[NSBundle mainBundle] pathForResource:@"C_Major_Scale" ofType:@"mid"];
    OPSong* song = [[OPSong alloc] initWithMIDIFile:path];
    self.song = song;
    */
    self.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    self.backgroundColor = [UIColor clearColor];
    self.tapeHeadLocation = 0.0f;
    self.contentWidth = self.bounds.size.width;
    self.horizontalScale = 1.0f;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
    [self addGestureRecognizer:self.panGesture];
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPinch:)];
    [self addGestureRecognizer:self.pinchGesture];
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

- (void)setSongObject:(OPSong*)s {
    self.song = s;
    OPSongPlayer* player = [[OPSongPlayer alloc] initWithSong:s];
    self.player = player;
    [self clearCurrentFeedback];
}

- (void)clearCurrentFeedback {
    [self.feedbackView clearFeedbackView];
    self.drawingOffset = 0.0f;
    self.contentWidth = self.bounds.size.width;
    [self setNeedsDisplay];
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
        self.pinchStartScale = self.horizontalScale;
        _isPinching = YES;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = pinch.scale;
        CGFloat newScale = self.pinchStartScale * (scale / 1.2f); // Scale down the scale factor (ITS SO META!)
        self.horizontalScale = newScale;
        _isPinching = YES;
    }
    if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled) {
        self.pinchStartScale = 1.0f;
        _isPinching = NO;
    }
    
    [self.feedbackView setNeedsDisplay];
    [self setNeedsDisplay];
}

- (void)setContentWidth:(CGFloat)contentWidth {
    _contentWidth = contentWidth;
    float viewWidth = self.bounds.size.width;
    self.tapeHeadLocation = CLAMP(contentWidth - viewWidth, 0.0f, viewWidth / 2);
    [self setNeedsDisplay];
}

- (void)setHorizontalScale:(CGFloat)contentScale {
    _horizontalScale = CLAMP(contentScale, MIN_HORIZONTAL_SCALE, MAX_HORIZONTAL_SCALE);
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    // Gets the context of this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    // Set some state vars for lines
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // Clear the space
    CGContextClearRect(context, rect);
    
    // Draw staff
    CGContextSetLineWidth(context, STAFF_LINEWIDTH);
    CGContextSetLineCap(context, kCGLineCapRound);
    for (NSInteger i=0; i<NUMBER_OF_STAFF_LINES; i++) {
        if (i == 0 ||
            i == NUMBER_OF_STAFF_LINES-1) {
            CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
            CGContextSetAlpha(context, 0.2f);
        } else {
            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetAlpha(context, 1.0f);
        }
        float y = self.bounds.size.height/2.0f+(i-NUMBER_OF_STAFF_LINES/2)*STAFF_LINE_SPACING;
        CGContextMoveToPoint(context, 0.0f, y);
        CGContextAddLineToPoint(context, self.bounds.size.width, y);
        CGContextStrokePath(context);
    }
    
    // Draw notes
    for (NSInteger i=0; i<self.song.notes.count; i++)
    {
        OPNote *n = [self.song.notes objectAtIndex:i];

        CGFloat width = (CGFloat)n.length * NOTE_LENGTH_SCALE_FACTOR * self.horizontalScale;
        CGFloat x = ((CGFloat)n.timestamp * NOTE_LENGTH_SCALE_FACTOR) * self.horizontalScale;
        CGFloat moved_x = x - self.drawingOffset;
        CGFloat y = REST_HEIGHT;
        if (n.nameIndex != kNoteNameNone) {
            CGFloat staffLine = [self staffLineForNote:n withLowestOctave:self.song.lowestOctave];
            y = [self heightForStaffLine:staffLine];
        }
        
        UIColor* color = [self colorForNote:n];
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGRect noteRect = CGRectMake(moved_x, y, width, NOTE_HEIGHT);
        UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:noteRect cornerRadius:NOTE_CORNER_RADIUS];
        [path fillWithBlendMode:kCGBlendModeNormal alpha:0.8f];
    }
    
    // Draw tapehead
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 4.0f);
    CGContextSetAlpha(context, 0.5f);
    CGContextMoveToPoint(context, self.tapeHeadLocation, 0.0);
    CGContextAddLineToPoint(context, self.tapeHeadLocation, self.bounds.size.height);
    CGContextStrokePath(context);
    
    // Undo any state changes that we did in this function
    CGContextRestoreGState(context);
}

- (UIColor*)colorForNote:(OPNote *)note {
    // CGFloat i = (CGFloat)note.noteIndex / (CGFloat)MAX_NOTE_INDEX;
    if (!note.isNoteAccidental) {
        return [UIColor colorWithRed:0.1 green:0.1 blue:1.0 alpha:1.0f];
    } else {
        return [UIColor colorWithRed:0.1 green:1.0 blue:0.1 alpha:1.0f];
    }
}

- (CGFloat)staffLineForNote:(OPNote*)note withLowestOctave:(NSInteger)lowestOctave;
{
    NSDictionary* lineForNoteDict = @{
                                      @"C6": @0,
                                      @"C#6": @0,
                                      @"D6": @1,
                                      @"D#6": @1,
                                      @"E6": @2,
                                      @"F6": @3,
                                      @"F#6": @3,
                                      @"G6": @4,
                                      @"G#6": @4,
                                      @"A7": @5,
                                      @"A#7": @5,
                                      @"B7": @6,
                                      @"C7": @7,
                                      @"C#7": @7,
                                      @"D7": @8,
                                      @"D#7": @8,
                                      @"E7": @9,
                                      @"F7": @10,};
    CGFloat position = [[lineForNoteDict objectForKey:note.staffNameForNote] floatValue] * 2;
    // NSLog(@"Note: %@, Staff Line: %.1f", note.staffNameForNote, position);
    return position;
}

- (CGFloat)heightForStaffLine:(CGFloat)staffLine
{
    CGFloat height = (self.bounds.size.height - 20.0f) -
        (staffLine / 4.0f * STAFF_LINE_SPACING) -
        (NOTE_HEIGHT / 2.0f);
    return height;
}

@end
