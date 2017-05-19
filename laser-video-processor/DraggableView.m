//
//  DraggableView.m
//  Laser Processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import "DraggableView.h"
#import <Appkit/AppKit.h>

@implementation DraggableView {
    #define DRAG_UNSTART_TEXT @"Drag .MOV file to start"
    #define DRAG_ENTER_TEXT @"Release to start"
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    self.centerLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.centerLabel.translatesAutoresizingMaskIntoConstraints = false;
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:self.centerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.centerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.centerLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.8 constant:0.0],
                             ];
    [self addSubview:self.centerLabel positioned:NSWindowBelow relativeTo:nil];
    [self addConstraints:constraints];
    
    [self.centerLabel setBezeled:NO];
    [self.centerLabel setDrawsBackground:NO];
    [self.centerLabel setEditable:NO];
    [self.centerLabel setSelectable:NO];
    [self.centerLabel setAlignment:NSTextAlignmentCenter];
    [self.centerLabel setTextColor:[NSColor grayColor]];
    
    self.centerLabel.stringValue = DRAG_UNSTART_TEXT;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    self.centerLabel.stringValue = DRAG_ENTER_TEXT;
    return NSDragOperationLink;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    self.centerLabel.stringValue = DRAG_ENTER_TEXT;
    return NSDragOperationLink;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    self.centerLabel.stringValue = DRAG_UNSTART_TEXT;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    self.centerLabel.stringValue = DRAG_UNSTART_TEXT;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
    
    if (filenames.count == 1) {
        NSLog(@"DraggableView received %@", filenames[0]);
        if (_delegate != nil)
            [_delegate fileReceived:filenames[0]];
    }
    
    return YES;
}

@end
