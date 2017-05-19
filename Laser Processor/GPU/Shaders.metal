//
//  innerProduct.metal
//  Laser Processor
//
//  Created by Xinhong LIU on 4/2/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void innerProduct(const device float *baseImagePixels [[ buffer(0) ]],
                         const device float *imagePixels [[ buffer(1) ]],
                         const device int *parameters [[buffer(2)]],
                         device float *dotProductVector [[ buffer(3) ]],
                         device float *baseDotProductVector [[ buffer(4) ]],
                         device float *imageDotProductVector [[ buffer(5) ]],
                         device float *outVector [[ buffer(6) ]],
                         uint id [[ thread_position_in_grid ]]) {
    
    int imageRow = parameters[0];
    int imageCol = parameters[1];
    int offsetI = parameters[2];
    int offsetJ = parameters[3];
    
    int i = id % imageRow;
    int j = (id - i) / imageRow;
    
    int _i = i + offsetI;
    int _j = j + offsetJ;
    if (_i < 0 || _j < 0 || _i >= imageRow || _j >= imageCol) {
        dotProductVector[id] = 0.0;
        baseDotProductVector[id] = 0.0;
        imageDotProductVector[id] = 0.0;
    } else {
        int index = j * imageRow + i;
        int index4 = index * 4;
        dotProductVector[id] = baseImagePixels[index] * imagePixels[index4];
        baseDotProductVector[id] = baseImagePixels[index] * baseImagePixels[index];
        imageDotProductVector[id] = imagePixels[index4] * imagePixels[index4];
    }
    
    
    if (id > 0) return;
    outVector[0] = 1.0;
}

