//
//  OPFileListViewController.m
//  On Pitch
//
//  Created by Foster Lockwood on 4/25/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPFileListViewController.h"
#import "OPViewController.h"
#import "OPSongView.h"
#import "OPSong.h"

enum kSectionIndex {
    kSectionFileNames,
    kSectionNoFiles,
};

@interface OPFileListViewController ()

@property (strong) NSArray* fileNames;

- (void)cancelPressed;
- (void)fileNameSelected:(NSString*)path;

@end

@implementation OPFileListViewController

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.mainController closeTapeDeckWithBlock:nil];
    }];
}

- (void)fileNameSelected:(NSString*)path {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.mainController closeTapeDeckWithBlock:^{
            OPSong* song = [[OPSong alloc] initWithMIDIFile:path];
            [self.mainController.songView setSongObject:song];
        }];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    
    self.navigationItem.leftBarButtonItem = cancel;
    
    NSString* path = [OPAppDelegate documentsPath];
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:10];
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (NSString* str in files) {
        if ([[str pathExtension] caseInsensitiveCompare:@"mid"] == NSOrderedSame ||
            [[str pathExtension] caseInsensitiveCompare:@"midi"] == NSOrderedSame) {
            [array addObject:str];
        }
    }
    self.fileNames = array;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == kSectionFileNames) {
        return [self.fileNames count];
    } else if (section == kSectionNoFiles) {
        if (self.fileNames.count == 0) {
            return 1;
        } else {
            return 0;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionFileNames) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell"];
        NSString* name = [self.fileNames objectAtIndex:indexPath.row];
        [cell.textLabel setText:[[name lastPathComponent] stringByDeletingPathExtension]];
        return cell;
    } else if (indexPath.section == kSectionNoFiles) {
        return [tableView dequeueReusableCellWithIdentifier:@"noFileCell"];
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kSectionFileNames) {
        NSString* str = [self.fileNames objectAtIndex:indexPath.row];
        [self fileNameSelected:[[OPAppDelegate documentsPath] stringByAppendingPathComponent:str]];
    }
}

@end
