//
//  OPViewController.m
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPViewController.h"
#import "OPMicInput.h"

@interface OPViewController ()

- (void)testTimer;

@end

@implementation OPViewController

- (IBAction)muteButtonPressed:(id)sender {
    BOOL muted = [[OPMicInput sharedInput] isMuted];
    [[OPMicInput sharedInput] setMuted:!muted];
}

- (void)testTimer {
    float pitch = [[OPMicInput sharedInput] currentLoudestPitchMicHears];
    if ([[OPMicInput sharedInput] currentVolumeMicHears] > 20.0f) {
        self.numberLabel.text = [NSString stringWithFormat:@"%.2f Hz", pitch];
    } else {
        self.numberLabel.text = [NSString stringWithFormat:@"Tone Too Quiet"];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(testTimer) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
