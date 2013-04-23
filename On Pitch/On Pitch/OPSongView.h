//
//  OPSongView.h
//  On Pitch
//
//  Created by Dan Fortunato on 3/11/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPSong.h"

#warning SCALING IS TURNED OFF
#define MIN_HORIZONTAL_SCALE 0.5f
#define MAX_HORIZONTAL_SCALE 1.0f

@class OPFeedbackView;

@interface OPSongView : UIView

@property (assign, nonatomic) CGFloat drawingOffset;
@property (assign, nonatomic) CGFloat contentWidth;
@property (assign, nonatomic) CGFloat horizontalScale;
@property (readonly) BOOL isPanning;
@property (readonly) BOOL isPinching;

@property (readonly) CGFloat tapeHeadLocation;

@property (weak) IBOutlet OPFeedbackView* feedbackView;

- (id)initWithSong:(OPSong *)s;

- (void)clearCurrentFeedback;


@end
