//
//  ViewController.m
//  laser-video-processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "laser_video_processor-Swift.h"
#import "CropViewController.h"
#import <AppKit/AppKit.h>

@class VideoProcessor;
@class Preference;
@class DataSetManager;

@implementation ViewController {
    VideoProcessor *videoProcessor;
    NSOperationQueue *backgroundQueue;
    CropViewController *cropViewController;
    AVAsset *asset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ((DraggableView *)(self.view)).delegate = self;
    backgroundQueue = [[NSOperationQueue alloc] init];
    
    [Preference setMaxShifting:0];
    [Preference setChannel:3];
    [Preference setBaseImageGap:1];
    [self.absoluteModeCheckBox setIntValue:[Preference absoluteMeasurementOn]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startProcess)
                                                 name:@"startProcess"
                                               object:nil];
}

- (IBAction)absoluteModeChanged:(id)sender {
    NSButton *absoluteModeCheckBox = (NSButton *)sender;
    int value = absoluteModeCheckBox.intValue;
    [Preference setAbsoluteMeasurement:value > 0];
}

- (void)fileReceived:(NSString *)path {
    asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    
    NSLog(@"%@ loaded", asset);
    if (asset != nil) {
        NSError *error;
        videoProcessor = [[VideoProcessor alloc] initWithVideoAsset:asset error:&error];
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        }
        
        CGImageRef thumbnail = [videoProcessor getThumbnail];
        cropViewController = (CropViewController *)[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"crop-view-controller"];
        cropViewController.thumbnail = thumbnail;
        [self presentViewControllerAsSheet:cropViewController];
    }
}

- (void)startProcess {
    [backgroundQueue addOperationWithBlock:^{
        [self process];
    }];
}

- (void)process {
    NSError *error;
    [videoProcessor printVideoMetaDataAndReturnError:&error];
    if (error != nil) {
        NSLog(@"%@", error);
        return;
    }
    [videoProcessor process:^(NSInteger progress) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.progressLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)progress];
        }];
    } completeHandler:^(NSInteger count) {
        [[[DataSetManager alloc] init] saveDataSet:videoProcessor.calculationManager];
        [DataSetManager clearCacheImages];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.previewImageView.hidden = true;
            self.progressLabel.stringValue = @"";
        }];
    } frameHandler:^(CGImageRef image) {
        NSImage *nsImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.previewImageView.hidden = false;
            self.previewImageView.image = nsImage;
        }];
    }];
}

@end
