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

@property (weak) IBOutlet UILabel* titleLabel;
@property (weak) IBOutlet UILabel* noteLabel;
@property (weak) IBOutlet UILabel* freqLabel;
@property (weak) IBOutlet OPFeedbackView* feedbackView;
@property (weak) IBOutlet OPSongView* songView;
@property (weak) IBOutlet UILabel* tempoLabel;
@property (weak, nonatomic) IBOutlet UISlider *tempSlider;

- (IBAction)muteButtonPressed:(id)sender;
- (IBAction)metronomeTempoChanged:(UISlider*)sender;
- (IBAction)metronomeButtonTapped:(UIButton*)sender;

- (IBAction)startSamplingButtonPressed:(UIButton*)sender;
- (IBAction)clearButtonPressed:(id)sender;

@end
