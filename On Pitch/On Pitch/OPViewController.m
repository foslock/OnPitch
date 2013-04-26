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
#import "OPSongPlayer.h"
#import "OPFileListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <DropboxSDK/DropboxSDK.h>

#define TAPE_OPEN_INTERVAL 0.35f

#define FEEDBACK_VIEW_REFRESH_RATE (1.0f/60.0f)

@interface OPViewController ()

@property (assign) BOOL isSampling;
@property (assign) BOOL isTapeOpen;
@property (assign) BOOL isTapeAnimating;

- (void)updateFeedbackView:(NSTimer*)timer;
- (void)tapeTapped:(UITapGestureRecognizer*)tap;

@end

@implementation OPViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
        UINavigationController* nav = (UINavigationController*)[segue destinationViewController];
        UIViewController* controller = [nav.viewControllers objectAtIndex:0];
        if ([controller isKindOfClass:[OPFileListViewController class]]) {
            OPFileListViewController* fileList = (OPFileListViewController*)controller;
            fileList.mainController = self;
        }
    }
}

- (IBAction)metronomeTempoChanged:(UISlider*)sender {
    [[OPMetronome sharedMetronome] setBeatsPerMinute:sender.value];
    [self.tempoLabel setText:[NSString stringWithFormat:@"%.0f bpm", sender.value]];
}

- (IBAction)metronomeButtonTapped:(UIButton*)sender {
    if (![[OPMetronome sharedMetronome] isRunning]) {
        [[OPMetronome sharedMetronome] startMetronome];
    } else {
        [[OPMetronome sharedMetronome] stopMetronome];
    }
}

- (IBAction)loadFilePressed:(UIButton*)sender {
    if (!self.isTapeOpen) {
        [self openTapeDeckWithBlock:^{
            [self performSegueWithIdentifier:@"showFileListController" sender:self];
        }];
    } else {
        [self closeTapeDeckWithBlock:nil];
    }
}

- (void)tapeTapped:(UITapGestureRecognizer*)tap {
    [self loadFilePressed:nil];
}

- (void)closeTapeDeckWithBlock:(void (^)(void))block {
    self.isTapeOpen = NO;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    anim.fromValue = [NSNumber numberWithFloat:0.6f];
    anim.toValue = [NSNumber numberWithFloat:0.0f];
    anim.duration = TAPE_OPEN_INTERVAL/2;
    [self.tapeView.layer addAnimation:anim forKey:@"shadowOpacity"];
    self.tapeView.layer.shadowOpacity = 0.0f;
    
    [UIView animateWithDuration:TAPE_OPEN_INTERVAL delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tapeView.layer.transform = CATransform3DIdentity;
    } completion:^(BOOL finished) {
        if (finished)
            if (block) {block();}
    }];
}

- (void)openTapeDeckWithBlock:(void (^)(void))block {
    self.isTapeOpen = YES;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    anim.fromValue = [NSNumber numberWithFloat:0.0f];
    anim.toValue = [NSNumber numberWithFloat:0.6f];
    anim.duration = TAPE_OPEN_INTERVAL;
    [self.tapeView.layer addAnimation:anim forKey:@"shadowOpacity"];
    self.tapeView.layer.shadowOpacity = 0.6f;
    
    [UIView animateWithDuration:TAPE_OPEN_INTERVAL delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = 1.0 / -700.0f;
        CATransform3D transform = CATransform3DRotate(perspective, -M_PI / 4, 1.0f, 0.0f, 0.0f);
        self.tapeView.layer.transform = transform;
    } completion:^(BOOL finished) {
        if (finished)
            if (block) {block();}
    }];
}

- (IBAction)startSamplingButtonPressed:(UIButton*)sender {
    if (self.isSampling) {
        self.isSampling = NO;
        // [sender setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        // [sender setTitle:@"Stop" forState:UIControlStateNormal];
        [self.songView clearCurrentFeedback];
        self.isSampling = YES;
    }
}

- (IBAction)clearButtonPressed:(id)sender {
    [self.songView setHorizontalScale:1.0f];
    [self.songView clearCurrentFeedback];
}

- (void)updateFeedbackView:(NSTimer*)timer {
    float pitch = [[OPMicInput sharedInput] currentLoudestPitchMicHears];
    float magnitude = [[OPMicInput sharedInput] currentVolumeMicHears];
    
    if (self.isSampling && !self.songView.isPanning && !self.songView.isPinching) {
        // Adds sample to view
        FeedbackSample* sample = [[FeedbackSample alloc] init];
        sample.sampleValue = pitch;
        sample.sampleStrength = CLAMP(magnitude, 0.2f, 1.0f);
        sample.sampleColor = [UIColor colorWithWhite:0.0f alpha:sample.sampleStrength];
        [self.feedbackView pushSampleValue:sample];
    } else {
        self.isSampling = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tempoLabel.textColor = [UIColor darkGrayColor];
    
    [self.tapeView setAnchorPoint:CGPointMake(0.5f, 1.0f) forView:self.tapeView];
    self.tapeView.layer.shadowOffset = CGSizeMake(0.0f, -3.0f);
    self.tapeView.layer.shadowRadius = 4.0f;
    self.tapeView.userInteractionEnabled = YES;

    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapeTapped:)];
    [tap setNumberOfTapsRequired:1];
    [self.tapeView addGestureRecognizer:tap];

    float freqLow = [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:27]; // 39
    float freqHigh = [[OPNoteTranslator translator] frequencyFromNoteStaffIndex:48]; // 60
    self.feedbackView.lowerValueLimit = freqLow; // C4
    self.feedbackView.upperValueLimit = freqHigh; // to A6
    
    UIImageView *background = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"TEXTUREDBG"]];
    [self.view insertSubview: background atIndex:0];
        
    // set custom UISlider images
    UIImage *sliderMin = [UIImage imageNamed:@"SLIDER_CAP_LEFT"];
    UIImage *sliderMax = [UIImage imageNamed:@"SLIDER_CAP_RIGHT"];
    UIImage *sliderHead = [UIImage imageNamed:@"SLIDER_HEAD_FINAL"];
    
    sliderMin = [sliderMin resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 10.0, 0, 0)];
    sliderMax = [sliderMax resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 10.0)];
    
    // set temp slider images
    [self.tempSlider setMinimumTrackImage:sliderMin forState:UIControlStateNormal];
    [self.tempSlider setMaximumTrackImage:sliderMax forState:UIControlStateNormal];
    [self.tempSlider setThumbImage: sliderHead forState:UIControlStateNormal];
    
    [self.volSlider setMinimumTrackImage:sliderMin forState:UIControlStateNormal];
    [self.volSlider setMaximumTrackImage:sliderMax forState:UIControlStateNormal];
    [self.volSlider setThumbImage: sliderHead forState:UIControlStateNormal];
    
    [[OPMicInput sharedInput] startAnalyzingMicInput];
	[NSTimer scheduledTimerWithTimeInterval:FEEDBACK_VIEW_REFRESH_RATE
                                     target:self
                                   selector:@selector(updateFeedbackView:)
                                   userInfo:nil
                                    repeats:YES];
}

- (IBAction)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    } else {
        [[DBSession sharedSession] unlinkAll];
        [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!"
                                    message:@"Your dropbox account has been unlinked"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil]
         show];
    }
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
