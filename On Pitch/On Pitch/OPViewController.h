//
//  OPViewController.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OPFeedbackView, OPSongView;

@interface OPViewController : UIViewController

@property (weak) IBOutlet OPFeedbackView* feedbackView;
@property (weak) IBOutlet OPSongView* songView;
@property (weak) IBOutlet UILabel* tempoLabel;
@property (weak, nonatomic) IBOutlet UISlider *tempSlider;
@property (weak, nonatomic) IBOutlet UISlider *volSlider;

@property (weak) IBOutlet UIImageView* tapeView;

- (IBAction)metronomeTempoChanged:(UISlider*)sender;
- (IBAction)metronomeButtonTapped:(UIButton*)sender;

- (IBAction)loadFilePressed:(UIButton*)sender;

- (void)closeTapeDeckWithBlock:(void (^)(void))block;
- (void)openTapeDeckWithBlock:(void (^)(void))block;

- (IBAction)startSamplingButtonPressed:(UIButton*)sender;
- (IBAction)clearButtonPressed:(id)sender;

- (IBAction)didPressLink; // Dropbox linking

@end
