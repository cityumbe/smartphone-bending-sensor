//
//  DraggableView.h
//  Laser Processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DraggableViewDelegate.h"

@interface DraggableView : NSView <NSDraggingDestination>

@property (weak) NSObject<DraggableViewDelegate> *delegate;
@property NSTextField *centerLabel;

@end
