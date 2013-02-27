//
//  OPViewController.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/13/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OPViewController : UIViewController

@property (weak) IBOutlet UILabel* titleLabel;
@property (weak) IBOutlet UILabel* noteLabel;
@property (weak) IBOutlet UILabel* freqLabel;

- (IBAction)muteButtonPressed:(id)sender;

@end
