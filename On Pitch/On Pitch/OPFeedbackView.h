//
//  OPFeedbackView.h
//  On Pitch
//
//  Created by Foster Lockwood on 3/10/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OPSongView;

@interface FeedbackSample : NSObject

@property (assign, nonatomic) CGFloat sampleValue; // The actual value to be plotted
@property (strong, nonatomic) UIColor* sampleColor; // Color to be drawn
@property (assign, nonatomic) CGFloat sampleStrength; // From 0.0 to 1.0, represents volume

@end

@interface OPFeedbackView : UIView

@property (assign) CGFloat upperValueLimit; // The upper limit of the values being sampled and drawn
@property (assign) CGFloat lowerValueLimit; // The lower limit...

@property (weak) IBOutlet OPSongView* parentSongView;

// 'sample' can be any value, but will only be drawn if between the lower and upper limits
- (void)pushSampleValue:(FeedbackSample*)sample;

// Clears the view when it gets drawn next
- (void)clearFeedbackView;

@end
