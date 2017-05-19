//
//  CropViewController.h
//  Laser Processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CropViewController : NSViewController <NSGestureRecognizerDelegate>

@property (weak) IBOutlet NSImageView *thumbnailImageView;
@property CGImageRef thumbnail;
- (IBAction)close:(id)sender;

@end
