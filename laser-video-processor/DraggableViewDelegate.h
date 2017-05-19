//
//  DraggableViewDelegate.h
//  Laser Processor
//
//  Created by Xinhong LIU on 28/6/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#ifndef DraggableViewDelegate_h
#define DraggableViewDelegate_h

@protocol DraggableViewDelegate <NSObject>

- (void)fileReceived: (NSString *)path;

@end

#endif /* DraggableViewDelegate_h */
