//
//  ViewController.h
//  laser-video-processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DraggableView.h"

@interface ViewController : NSViewController<DraggableViewDelegate>

@property (weak) IBOutlet NSImageView *previewImageView;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSButton *absoluteModeCheckBox;
- (IBAction)absoluteModeChanged:(id)sender;

@end

