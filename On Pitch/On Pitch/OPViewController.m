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

@interface OPViewController ()

- (void)testTimer;

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

- (void)testTimer {
    float pitch = [[OPMicInput sharedInput] currentLoudestPitchMicHears];
    NSInteger index = [[OPNoteTranslator translator] noteStaffIndexForFrequency:pitch];
    NSLog(@"f: %f p:%d", pitch, index);
    OPNote* note = [OPNote noteFromStaffIndex:index];
    if ([[OPMicInput sharedInput] currentVolumeMicHears] > 20.0f) {
        self.numberLabel.text = [NSString stringWithFormat:@"%@", note.staffNameForNote];
    } else {
        self.numberLabel.text = [NSString stringWithFormat:@"Tone Too Quiet"];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[OPMicInput sharedInput] startAnalyzingMicInput];
	[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(testTimer) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
