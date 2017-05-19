//
//  OpenCVWrapper.h
//  Laser Processor
//
//  Created by Xinhong LIU on 4/2/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#ifndef OpenCVWrapper_h
#define OpenCVWrapper_h

#import <Foundation/Foundation.h>

@interface OpenCVWrapper : NSObject

+ (float)microShiftInnerProductGPU: (UInt8 *)baseImagePixels imagePixels: (UInt8 *)imagePixels imageRow: (int)imageRow imageCol: (int)imageCol maxShift: (int)maxShift;

@end


#endif /* OpenCVWrapper_h */
