//
//  CropViewController.m
//  Laser Processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import "CropViewController.h"
#import "laser_video_processor-Swift.h"

@class Preference;

@interface CropViewController ()

@end

@implementation CropViewController {
    CGPoint start;
    NSView *rectView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.thumbnailImageView.image = [[NSImage alloc] initWithCGImage:self.thumbnail size:NSZeroSize];
    
    NSPanGestureRecognizer *panGestureRecognizer = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.thumbnailImageView addGestureRecognizer:panGestureRecognizer];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    CGFloat width = self.thumbnailImageView.frame.size.width;
    CGFloat height = self.thumbnailImageView.frame.size.height;
    
    NSArray<NSNumber *> *sampleArea = [Preference getSampleArea];
    
    CGRect rect = NSMakeRect(sampleArea[0].floatValue * width / 100, (100 - sampleArea[3].floatValue) * height / 100, (sampleArea[1].floatValue - sampleArea[0].floatValue) * width / 100, (sampleArea[3].floatValue - sampleArea[2].floatValue) * height / 100);
    rectView = [[NSView alloc] initWithFrame:rect];
    [rectView setWantsLayer: true];
    rectView.layer.borderWidth = 3.0;
    rectView.layer.borderColor = [NSColor redColor].CGColor;
    [self.view addSubview:rectView positioned:NSWindowAbove relativeTo:self.thumbnailImageView];
}

- (void)swap:(NSInteger *)a with:(NSInteger *)b {
    NSInteger tmp = *a;
    *a = *b;
    *b = tmp;
}

- (void)onPan:(NSPanGestureRecognizer *)panGestureRecognizer {
    CGPoint location = [panGestureRecognizer locationInView:self.thumbnailImageView];
    if (panGestureRecognizer.state == NSGestureRecognizerStateBegan) {
        start = location;
        NSLog(@"pan start %f, %f", start.x, start.y);
    } else if (panGestureRecognizer.state == NSGestureRecognizerStateEnded) {
        CGPoint end = location;
        NSLog(@"pan end %f, %f", end.x, end.y);
        CGFloat width = self.thumbnailImageView.frame.size.width;
        CGFloat height = self.thumbnailImageView.frame.size.height;
        NSInteger xStart = 100 * start.x / width;
        NSInteger xEnd = 100 * end.x / width;
        NSInteger yStart = 100 * start.y / height;
        NSInteger yEnd = 100 * end.y / height;
        if (xStart > xEnd) [self swap:&xStart with:&xEnd];
        if (yStart > yEnd) [self swap:&yStart with:&yEnd];
        NSArray *sampleArea = @[[NSNumber numberWithInteger:xStart],
                                [NSNumber numberWithInteger:xEnd],
                                [NSNumber numberWithInteger:100 - yEnd],
                                [NSNumber numberWithInteger:100 - yStart]];
        [Preference setSampleArea:sampleArea];
        NSLog(@"Sample area = %@", sampleArea);
    } else if (panGestureRecognizer.state == NSGestureRecognizerStateChanged) {
        CGPoint end = location;
        CGFloat width = self.thumbnailImageView.frame.size.width;
        CGFloat height = self.thumbnailImageView.frame.size.height;
        NSInteger xStart = 100 * start.x / width;
        NSInteger xEnd = 100 * end.x / width;
        NSInteger yStart = 100 * start.y / height;
        NSInteger yEnd = 100 * end.y / height;
        if (xStart > xEnd) [self swap:&xStart with:&xEnd];
        if (yStart > yEnd) [self swap:&yStart with:&yEnd];
        rectView.frame = NSMakeRect(xStart * width / 100, yStart * height / 100, (xEnd - xStart) * width / 100, (yEnd - yStart) * height / 100);
    }
}

- (IBAction)close:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startProcess" object:nil];
    [self dismissController:nil];
}

@end
