//
//  OpenCVWrapper.m
//  Laser Processor
//
//  Created by Xinhong LIU on 4/2/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenCVWrapper.h"
#include <opencv2/opencv.hpp>

using namespace cv;

@implementation OpenCVWrapper: NSObject

+ (float)microShiftInnerProductGPU: (UInt8 *)baseImagePixels imagePixels: (UInt8 *)imagePixels imageRow: (int)imageRow imageCol: (int)imageCol maxShift: (int)maxShift {
    
    Mat baseImage(imageRow, imageCol, CV_8UC1);
    Mat image(imageRow, imageCol, CV_8UC1);
    
    for (int i = 0; i < imageRow; ++i) {
        for (int j = 0; j < imageCol; ++j) {
            int index = j + imageRow + i;
            int index4 = 4 * index;
            baseImage.at<uchar>(i, j) = baseImagePixels[index4];
            image.at<uchar>(i, j) = imagePixels[index4];
        }
    }
    
    Mat result;
    
    matchTemplate(baseImage, image, result, CV_TM_CCORR);
    
    normalize(result, result, 0, 1, NORM_MINMAX, -1, Mat());
    
    double min_v, max_v;
    
    minMaxIdx(result, &min_v, &max_v);
    
    return max_v;
}

@end