//
//  OPSongView.h
//  On Pitch
//
//  Created by Dan Fortunato on 3/11/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPSong.h"

@interface OPSongView : UIView

@property (assign, nonatomic) float drawingOffset;

- (id)initWithSong:(OPSong *)s;


@end
