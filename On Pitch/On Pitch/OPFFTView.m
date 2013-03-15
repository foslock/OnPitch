//
//  OPFFTView.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/14/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPFFTView.h"
#import "OPMicInput.h"
#import "OPAudioHandler.h"

@interface OPFFTView ()

@property (assign) int32_t* fftDataPointer;
@property (assign) NSUInteger fftDataLength;

@end

@implementation OPFFTView

- (void)initMe {
    self.fftDataPointer = [[OPMicInput sharedInput] audioHandler].fftDataBuffer;
    self.fftDataLength = [[OPMicInput sharedInput] audioHandler].fftLength;
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(setNeedsDisplay) userInfo:nil repeats:YES];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initMe];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initMe];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    int32_t* data = self.fftDataPointer;
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    int inc = 8;
    
    float maxValue = 0.0f;
    int maxValueIndex = 0;
    for (int i = 0; i < self.fftDataLength; i += inc) {
        float val = fabsf(data[i]);
        if (val > maxValue) {
            maxValue = val;
            maxValueIndex = i;
        }
    }
    CGContextMoveToPoint(context, (self.bounds.size.width / (self.fftDataLength)) * maxValueIndex, 0.0f);
    CGContextAddLineToPoint(context, (self.bounds.size.width / (self.fftDataLength)) * maxValueIndex, self.bounds.size.height);
    
    // NSLog(@"%f", maxValue);
    
    for (int i = 0; i < self.fftDataLength; i += inc) {
        float value = fabsf(data[i]);
        float x_value = (self.bounds.size.width / (self.fftDataLength)) * i;
        float y_value = ((float)value / (float)maxValue) * self.bounds.size.height;
        if (i == 0) {
            CGContextMoveToPoint(context, x_value, y_value);
        }
        CGContextAddLineToPoint(context, x_value, y_value);
    }
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}


@end
