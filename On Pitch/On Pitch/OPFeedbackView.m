//
//  OPFeedbackView.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPFeedbackView.h"
#import <QuartzCore/QuartzCore.h>

#define DISTANCE_PER_SAMPLE 8.0f
#define MAX_LINE_WIDTH 6.0f

@implementation FeedbackSample

@end

@interface OPFeedbackView ()

@property (strong) NSMutableArray* queueArray;
@property (strong) UIPanGestureRecognizer* panGesture;
@property (assign) CGFloat panStartOffset;

- (void)initMe;
- (void)viewDidPan:(UIPanGestureRecognizer*)pan;

CGPoint midPoint(CGPoint p1, CGPoint p2);

@end

@implementation OPFeedbackView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initMe];
    }
    return self;
}

// Called when created from nib
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initMe];
    }
    return self;
}

- (void)initMe {
    self.queueArray = [NSMutableArray array];
    self.sampleRate = 60.0f;
    self.lowerValueLimit = 0.0f;
    self.upperValueLimit = 1.0f;
    self.drawingOffset = 0.0f;
    self.contentWidth = self.bounds.size.width;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
    [self addGestureRecognizer:self.panGesture];
    self.backgroundColor = [UIColor clearColor];
    [self setOpaque:YES];
}

- (void)pushSampleValue:(FeedbackSample *)sample {
    [self.queueArray addObject:sample];
    self.contentWidth += 8.0f;
    if ([self.queueArray count] > ((self.bounds.size.width / 2) / DISTANCE_PER_SAMPLE)) {
        self.drawingOffset += DISTANCE_PER_SAMPLE;
    }
    [self setNeedsDisplay];
}

- (void)clearFeedbackView {
    [self.queueArray removeAllObjects];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)viewDidPan:(UIPanGestureRecognizer*)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.panStartOffset = self.drawingOffset;
    }
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint offset = [pan translationInView:self];
        float max = MAX(self.contentWidth - self.bounds.size.width, 0.0f);
        self.drawingOffset = CLAMP(self.panStartOffset - offset.x, 0.0f, max);
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        self.panStartOffset = 0.0f;
    }
    
    [self setNeedsDisplay];
}

#pragma mark - Drawing!

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (CGPoint)pointForSample:(FeedbackSample*)sample {
    int index = [self.queueArray indexOfObject:sample];
    float drawableRange = self.upperValueLimit - self.lowerValueLimit;
    float drawableHeight = self.bounds.size.height;
    float y_value = ((sample.sampleValue - self.lowerValueLimit) / drawableRange) * drawableHeight;
    float x_value = (float)index * DISTANCE_PER_SAMPLE - self.drawingOffset;
    return CGPointMake(x_value, drawableHeight - y_value);
}

- (void)drawRect:(CGRect)rect {
    // Gets the context of this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set some state vars for lines
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // Clear the space
    CGContextClearRect(context, rect);
    
    int startingIndex = self.drawingOffset / DISTANCE_PER_SAMPLE;
    int maxIndex = MIN(startingIndex + (self.bounds.size.width / DISTANCE_PER_SAMPLE) + 1, self.queueArray.count);
    // Draw anything within the current offset
    for (int i = startingIndex; i < maxIndex; i++) {
        FeedbackSample* currentSample = [self.queueArray objectAtIndex:i];
        FeedbackSample* prevSample1 = currentSample;
        if (i > 0) { prevSample1 = [self.queueArray objectAtIndex:i-1]; }
        FeedbackSample* prevSample2 = prevSample1;
        if (i > 1) { prevSample2 = [self.queueArray objectAtIndex:i-2]; }
        
        if (currentSample) {
            CGPoint mid1 = midPoint([self pointForSample:prevSample1],
                                    [self pointForSample:prevSample2]);
            CGPoint mid2 = midPoint([self pointForSample:currentSample],
                                    [self pointForSample:prevSample1]);
            CGContextMoveToPoint(context, mid1.x, mid1.y);
            CGContextAddQuadCurveToPoint(context,
                                         [self pointForSample:prevSample1].x,
                                         [self pointForSample:prevSample1].y,
                                         mid2.x, mid2.y);
            float width = CLAMP(MAX_LINE_WIDTH * currentSample.sampleStrength, 0.0f, MAX_LINE_WIDTH);
            CGContextSetLineWidth(context, width);
            CGContextSetStrokeColorWithColor(context, currentSample.sampleColor.CGColor);
            CGContextStrokePath(context);
        }
    }
}


@end
