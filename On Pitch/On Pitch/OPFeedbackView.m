//
//  OPFeedbackView.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPFeedbackView.h"
#import <QuartzCore/QuartzCore.h>

#define DISTANCE_PER_SAMPLE 4.0f
#define MAX_LINE_WIDTH 4.0f

@implementation FeedbackSample

@end

@interface OPFeedbackView ()

@property (strong) NSMutableArray* queueArray;
@property (strong) FeedbackSample* prevSample2;
@property (strong) FeedbackSample* prevSample1;
@property (strong) FeedbackSample* currentSample;

@property (assign) BOOL needsToClear;

- (void)initMe;

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
    self.lowerValueLimit = -2.0f;
    self.upperValueLimit = 2.0f;
    self.backgroundColor = [UIColor clearColor];
    [self setOpaque:NO];
}

- (void)pushSampleValue:(FeedbackSample *)sample {
    [self.queueArray addObject:sample];
    self.prevSample2 = self.prevSample1;
    self.prevSample1 = self.currentSample;
    self.currentSample = sample;
    
    // Just adjusting for the first couple samples
    if (!self.prevSample2) { self.prevSample2 = self.currentSample; }
    if (!self.prevSample1) { self.prevSample1 = self.currentSample; }
    
    // Update canvas!
    CGPoint mid1 = midPoint([self pointForSample:self.prevSample1],
                            [self pointForSample:self.prevSample2]);
    CGPoint mid2 = midPoint([self pointForSample:self.currentSample],
                            [self pointForSample:self.prevSample1]);
    
    // Make a virtual path of the current points
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(path, NULL, [self pointForSample:self.prevSample1].x,
                              [self pointForSample:self.prevSample1].y,
                              mid2.x, mid2.y);
    CGRect bounds = CGPathGetBoundingBox(path);
    CGPathRelease(path);
    
    CGRect drawBox = bounds;
    
    //Pad our values so the bounding box respects our line width
    drawBox.origin.x        -= MAX_LINE_WIDTH * 2;
    drawBox.origin.y        -= MAX_LINE_WIDTH * 2;
    drawBox.size.width      += MAX_LINE_WIDTH * 4;
    drawBox.size.height     += MAX_LINE_WIDTH * 4;
    
    // Saves whats already been drawn into a UIImage
    UIGraphicsBeginImageContext(drawBox.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIGraphicsEndImageContext();
    
    [self setNeedsDisplayInRect:drawBox];
}

- (void)clearFeedbackView {
    [self.queueArray removeAllObjects];
    self.currentSample = nil;
    self.prevSample2 = nil;
    self.prevSample1 = nil;
    self.needsToClear = YES;
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self clearFeedbackView];
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
    return CGPointMake((float)index * DISTANCE_PER_SAMPLE, drawableHeight - y_value);
}

- (void)drawRect:(CGRect)rect {
    // Gets the context of this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.needsToClear) {
        self.needsToClear = NO;
        CGContextClearRect(context, rect);
    }
    
    // Renders this view's layer
    [self.layer renderInContext:context];
    
    // Draw current line
    if (self.prevSample2 && self.prevSample1 && self.currentSample) {
        CGPoint mid1 = midPoint([self pointForSample:self.prevSample1],
                                [self pointForSample:self.prevSample2]);
        CGPoint mid2 = midPoint([self pointForSample:self.currentSample],
                                [self pointForSample:self.prevSample1]);
        CGContextMoveToPoint(context, mid1.x, mid1.y);
        CGContextAddQuadCurveToPoint(context,
                                     [self pointForSample:self.prevSample1].x,
                                     [self pointForSample:self.prevSample1].y,
                                     mid2.x, mid2.y);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        float width = CLAMP(MAX_LINE_WIDTH * self.currentSample.sampleStrength, 0.0f, MAX_LINE_WIDTH);
        CGContextSetLineWidth(context, width);
        CGContextSetAlpha(context, CLAMP(self.currentSample.sampleStrength, 0.1f, 1.0f));
        // CGContextSetBlendMode(context, kCGBlendModeDarken);
        CGContextSetStrokeColorWithColor(context, self.currentSample.sampleColor.CGColor);
        CGContextStrokePath(context);
    }
}


@end
