//
//  OPViewController.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPViewController.h"
#import "OPMicInput.h"
#import "OPNoteTranslator.h"
#import "OPNote.h"
#import "OPSong.h"
#import "OPMIDIParser.h"
#import "OPMetronome.h"
#import "OPFeedbackView.h"
#import "OPSongView.h"
#import <QuartzCore/QuartzCore.h>

#define FEEDBACK_VIEW_REFRESH_RATE (1.0f/60.0f)

@interface OPViewController ()

@property (assign) BOOL isSampling;

- (void)updateFeedbackView:(NSTimer*)timer;

@end

@implementation OPViewController

- (IBAction)muteButtonPressed:(id)sender {
    BOOL muted = [[OPMicInput sharedInput] isMuted];
    [[OPMicInput sharedInput] setMuted:!muted];
    if ([[OPMicInput sharedInput] isMuted]) {
        [(UIButton*)sender setTitle:@"Muted!" forState:UIControlStateNormal];
    } else {
        [(UIButton*)sender setTitle:@"Listening..." forState:UIControlStateNormal];
    }
}

- (IBAction)metronomeTempoChanged:(UISlider*)sender {
    [[OPMetronome sharedMetronome] setBeatsPerMinute:sender.value];
    [self.tempoLabel setText:[NSString stringWithFormat:@"%.0f bpm", sender.value]];
}

- (IBAction)metronomeButtonTapped:(UIButton*)sender {
    if (![[OPMetronome sharedMetronome] isRunning]) {
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
        [[OPMetronome sharedMetronome] startMetronome];
    } else {
        [sender setTitle:@"Start" forState:UIControlStateNormal];
        [[OPMetronome sharedMetronome] stopMetronome];
    }
}

- (IBAction)startSamplingButtonPressed:(UIButton*)sender {
    if (self.isSampling) {
        self.isSampling = NO;
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
        [self.songView clearCurrentFeedback];
        self.isSampling = YES;
    }
}

- (IBAction)clearButtonPressed:(id)sender {
    [self.songView clearCurrentFeedback];
}

- (void)updateFeedbackView:(NSTimer*)timer {
    float pitch = [[OPMicInput sharedInput] currentLoudestPitchMicHears];
    float magnitude = [[OPMicInput sharedInput] currentVolumeMicHears];
    NSInteger index = [[OPNoteTranslator translator] noteStaffIndexForFrequency:pitch];
    OPNote* note = [OPNote noteFromStaffIndex:index];
    float targetPitch = [note exactFrequencyFromNote];
    if (magnitude > 30.0f) {
        self.noteLabel.text = [NSString stringWithFormat:@"%@", note.staffNameForNote];
        self.freqLabel.hidden = NO;
        self.freqLabel.text = [NSString stringWithFormat:@"Heard: %.1f Hz\nTarget: %.1f Hz", pitch, targetPitch];
    } else {
        self.noteLabel.text = [NSString stringWithFormat:@"Tone Too Quiet"];
        self.freqLabel.hidden = YES;
    }
    
    if (self.isSampling && !self.songView.isPanning) {
        // Adds sample to view
        FeedbackSample* sample = [[FeedbackSample alloc] init];
        sample.sampleValue = pitch;
        sample.sampleStrength = magnitude / 50.0f;
        sample.sampleColor = [UIColor colorWithWhite:0.0f alpha:CLAMP(sample.sampleStrength - 0.1f, 0.0f, 1.0f)];
        [self.feedbackView pushSampleValue:sample];
    } else {
        self.isSampling = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.layer.shadowOpacity = 0.4f;
    self.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    self.titleLabel.layer.shadowRadius = 4.0f;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.noteLabel.textColor = [UIColor whiteColor];
    self.freqLabel.textColor = [UIColor whiteColor];
    self.tempoLabel.textColor = [UIColor whiteColor];
    
    self.feedbackView.lowerValueLimit = [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:39]; // C4
    self.feedbackView.upperValueLimit = [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:60]; // to A6
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"MASTER_BACKGROUND.png"]];
    
    // set custom UISlider images
    UIImage *sliderMin = [UIImage imageNamed:@"sliderPreWithCap.png"];
    UIImage *sliderMax = [UIImage imageNamed:@"sliderPostWithCap.png"];
    UIImage *sliderHead = [UIImage imageNamed:@"SLIDER_HEAD.png"];
    
    sliderMin = [sliderMin resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 40.0, 0, 0)];
    sliderMax = [sliderMax resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 40.0)];
    
    // set temp slider images
    [self.tempSlider setMinimumTrackImage:sliderMin forState:UIControlStateNormal];
    [self.tempSlider setMaximumTrackImage:sliderMax forState:UIControlStateNormal];
    [self.tempSlider setThumbImage: sliderHead forState:UIControlStateNormal];
    
    [[OPMicInput sharedInput] startAnalyzingMicInput];
	[NSTimer scheduledTimerWithTimeInterval:FEEDBACK_VIEW_REFRESH_RATE
                                     target:self
                                   selector:@selector(updateFeedbackView:)
                                   userInfo:nil
                                    repeats:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTempSlider:nil];
    [super viewDidUnload];
}
@end
