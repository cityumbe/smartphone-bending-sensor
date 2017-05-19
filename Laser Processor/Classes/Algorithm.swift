//
//  Algorithm.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 3/2/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//
// GPU part take inspiration from 
// http://memkite.com/blog/2014/12/15/data-parallel-programming-with-metal-and-swift-for-iphoneipad-gpu/

import MetalKit

class Algorithm {
    
    let device = MTLCreateSystemDefaultDevice()!
    var defaultLibrary: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLComputePipelineState!
    
    init() {
        print("maxThreadsPerThreadgroup: \(device.maxThreadsPerThreadgroup)");
        defaultLibrary = device.newDefaultLibrary()
        commandQueue = device.newCommandQueue()
        let innerProductProgram = defaultLibrary.newFunctionWithName("innerProduct")
        do {
            pipelineState = try device.newComputePipelineStateWithFunction(innerProductProgram!)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func microShiftInnerProductGPU(baseImagePixels: UnsafePointer<UInt8>, imagePixels: UnsafePointer<UInt8>, imageRow: Int, imageCol: Int, maxOffset: Int) -> Float {
        
        var values = [Float]()
        for i in -maxOffset...maxOffset {
            for j in -maxOffset...maxOffset {
                values.append(shiftInnerProductGPU(baseImagePixels, imagePixels: imagePixels, imageRow: imageRow, imageCol: imageCol, offsetI: i, offsetJ: j))
            }
        }
        print("\(values)")
        return values.maxElement()!
        
    }
    
    func shiftInnerProductGPU(baseImagePixels: UnsafePointer<UInt8>, imagePixels: UnsafePointer<UInt8>, imageRow: Int, imageCol: Int, offsetI: Int, offsetJ: Int) -> Float {
        
        let commandBuffer = commandQueue.commandBuffer()
        let computeCommandEncoder = commandBuffer.computeCommandEncoder()
        computeCommandEncoder.setComputePipelineState(pipelineState)
        
        let baseImagePixelsByteLength = 4 * imageRow * imageCol * sizeof(UInt8)
        let baseImagePixelsBuffer = device.newBufferWithBytes(baseImagePixels, length: baseImagePixelsByteLength, options: .OptionCPUCacheModeDefault)
        computeCommandEncoder.setBuffer(baseImagePixelsBuffer, offset: 0, atIndex: 0)
        
        let imagePixelsByteLength = 4 * imageRow * imageCol * sizeof(UInt8)
        let imagePixelsBuffer = device.newBufferWithBytes(imagePixels, length: imagePixelsByteLength, options: .OptionCPUCacheModeDefault)
        computeCommandEncoder.setBuffer(imagePixelsBuffer, offset: 0, atIndex: 1)
        
        let otherParametersByteLength = 4 * sizeof(Int32)
        var otherParameters = [Int32](count: 4, repeatedValue: 0)
        otherParameters[0] = Int32(imageRow)
        otherParameters[1] = Int32(imageCol)
        otherParameters[2] = Int32(offsetI)
        otherParameters[3] = Int32(offsetJ)
        let otherParametersBuffer = device.newBufferWithBytes(otherParameters, length: otherParametersByteLength, options: .CPUCacheModeDefaultCache)
        computeCommandEncoder.setBuffer(otherParametersBuffer, offset: 0, atIndex: 2)
        
        let dotProductByteLength = imageRow * imageCol * sizeof(Float)
        let dotProduct = [Float](count: imageRow * imageCol, repeatedValue: 0.0)
        let dotProductBuffer = device.newBufferWithBytes(dotProduct, length: dotProductByteLength, options: .CPUCacheModeWriteCombined)
        computeCommandEncoder.setBuffer(dotProductBuffer, offset: 0, atIndex: 3)
        
        let baseDotProductByteLength = imageRow * imageCol * sizeof(Float)
        let baseDotProduct = [Float](count: imageRow * imageCol, repeatedValue: 0.0)
        let baseDotProductBuffer = device.newBufferWithBytes(baseDotProduct, length: baseDotProductByteLength, options: .CPUCacheModeWriteCombined)
        computeCommandEncoder.setBuffer(baseDotProductBuffer, offset: 0, atIndex: 4)
        
        let imageDotProductByteLength = imageRow * imageCol * sizeof(Float)
        let imageDotProduct = [Float](count: imageRow * imageCol, repeatedValue: 0.0)
        let imageDotProductBuffer = device.newBufferWithBytes(imageDotProduct, length: imageDotProductByteLength, options: .CPUCacheModeWriteCombined)
        computeCommandEncoder.setBuffer(imageDotProductBuffer, offset: 0, atIndex: 5)
        
        let outputValuesByteLength = 1 * sizeof(Float)
        let outputValues = [Float](count: 1, repeatedValue: 0.0)
        let outputValuesBuffer = device.newBufferWithBytes(outputValues, length: outputValuesByteLength, options: .CPUCacheModeDefaultCache)
        //        let outputValuesBuffer = device.newBufferWithBytes(outputValues, length: outputValuesByteLength, options: .StorageModePrivate)
        computeCommandEncoder.setBuffer(outputValuesBuffer, offset: 0, atIndex: 6)
        
        // hardcoded to 32 for now (recommendation: read about threadExecutionWidth)
        let threadsPerGroup = MTLSize(width:32, height:1, depth:1)
        let numThreadgroups = MTLSize(width:(4 * imageRow * imageCol + 31) / 32, height:1, depth:1)
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let data = NSData(bytesNoCopy: outputValuesBuffer.contents(),
            length: outputValues.count * sizeof(Float), freeWhenDone: false)
        // b. prepare Swift array large enough to receive data from GPU
        var finalResultArray = [Float](count: outputValues.count, repeatedValue: 0.0)
        
        // c. get data from GPU into Swift array
        data.getBytes(&finalResultArray, length:outputValues.count * sizeof(Float))
        
        
        return finalResultArray[0]
    }
    
    class func microShiftInnerProduct(baseImagePixels: UnsafePointer<UInt8>, imagePixels: UnsafePointer<UInt8>, imageRow: Int, imageCol: Int, maxOffset: Int) -> Float {
        var values = [Float]()
        for i in -maxOffset...maxOffset {
            for j in -maxOffset...maxOffset {
                values.append(shiftInnerProduct(baseImagePixels, imagePixels: imagePixels, imageRow: imageRow, imageCol: imageCol, offsetI: i, offsetJ: j))
            }
        }
        print("\(values)")
        return values.maxElement()!
    }
    
    class func nonShiftInnerProduct(baseImagePixels: UnsafePointer<UInt8>, imagePixels: UnsafePointer<UInt8>, imageRow: Int, imageCol: Int) -> Float {
        return shiftInnerProduct(baseImagePixels, imagePixels: imagePixels, imageRow: imageRow, imageCol: imageCol, offsetI: 0, offsetJ: 0)
    }
    
    class func shiftInnerProduct(baseImagePixels: UnsafePointer<UInt8>, imagePixels: UnsafePointer<UInt8>, imageRow: Int, imageCol: Int, offsetI: Int, offsetJ: Int) -> Float {
        
        let channel = Preference.getChannel()
        
        let sampleArea = Preference.getSampleArea()
        
        let imageRowStart = 0
        let imageRowEnd = imageRow
        
        let imageColStart = 0
        let imageColEnd = imageCol
        
        // 2d inner product
        // algorithm modified from http://stackoverflow.com/a/6801185/2361752
        var dotProduct: Int = 0
        var baseDotProduct: Int = 0
        var imageDotProduct: Int = 0
        
        var sumBase: Int = 0
        var minBase: Int = 10000
        var maxBase: Int = -1
        var sumImage: Int = 0
        var minImage: Int = 10000
        var maxImage: Int = -1
        
        for i in imageRowStart...(imageRowEnd - 1) {
            for j in imageRowStart...(imageColEnd - 1) {
                autoreleasepool({ () -> () in
                    let _i = i + offsetI
                    let _j = j + offsetJ
                    if _i < imageRowStart || _j < imageColStart || _i >= imageRowEnd || _j >= imageColEnd {
                        
                    } else {
                        let index = imageRow * j + i
                        let index4 = index * 4;
                        let _index = imageRow * _j + _i
                        let _index4 = _index * 4 // because there are 4 channels
                        var baseImagePixel: Int
                        var imagePixel: Int
                        switch (channel) {
                        case 3:
                            baseImagePixel = Int(Float(baseImagePixels[index4]) * 0.2989)
                            baseImagePixel += Int(Float(baseImagePixels[index4 + 1]) * 0.5870)
                            baseImagePixel += Int(Float(baseImagePixels[index4 + 2]) * 0.1140)
                            imagePixel = Int(Float(imagePixels[_index4]) * 0.2989)
                            imagePixel += Int(Float(imagePixels[_index4 + 1]) * 0.5870)
                            imagePixel += Int(Float(imagePixels[_index4 + 2]) * 0.1140)
                        default:
                            baseImagePixel = Int(baseImagePixels[index4 + channel])
                            imagePixel = Int(imagePixels[_index4 + channel])
                        }
                        sumBase += baseImagePixel
                        sumImage += imagePixel
                        minBase = min(minBase, baseImagePixel)
                        maxBase = max(maxBase, baseImagePixel)
                        minImage = min(minImage, imagePixel)
                        maxImage = max(maxImage, imagePixel)
                    }
                })
            }
        }
        
        let averageBase = sumBase / imageRow / imageCol
        let averageImage = sumImage / imageRow / imageCol
        
        for i in imageRowStart...(imageRowEnd - 1) {
            for j in imageRowStart...(imageColEnd - 1) {
                autoreleasepool({ () -> () in
                    let _i = i + offsetI
                    let _j = j + offsetJ
                    if _i < imageRowStart || _j < imageColStart || _i >= imageRowEnd || _j >= imageColEnd {
                        
                    } else {
                        let index = imageRow * j + i
                        let index4 = index * 4;
                        let _index = imageRow * _j + _i
                        let _index4 = _index * 4 // because there are 4 channels
                        var baseImagePixel: Int
                        var imagePixel: Int
                        switch (channel) {
                        case 3:
                            baseImagePixel = Int(Float(baseImagePixels[index4]) * 0.2989)
                            baseImagePixel += Int(Float(baseImagePixels[index4 + 1]) * 0.5870)
                            baseImagePixel += Int(Float(baseImagePixels[index4 + 2]) * 0.1140)
                            imagePixel = Int(Float(imagePixels[_index4]) * 0.2989)
                            imagePixel += Int(Float(imagePixels[_index4 + 1]) * 0.5870)
                            imagePixel += Int(Float(imagePixels[_index4 + 2]) * 0.1140)
                        default:
                            baseImagePixel = Int(baseImagePixels[index4 + channel])
                            imagePixel = Int(imagePixels[_index4 + channel])
                        }
                        baseImagePixel -= averageBase
                        imagePixel -= averageImage
                        dotProduct += baseImagePixel * imagePixel
                        baseDotProduct += baseImagePixel * baseImagePixel
                        imageDotProduct += imagePixel * imagePixel
                    }
                })
            }
        }
        
        return Float(dotProduct) / sqrt(Float(baseDotProduct) * Float(imageDotProduct))
        
        // increase contrast
        
        let thresholdBase = (minBase + maxBase) / 3;
        let thresholdImage = (minImage + maxImage) / 3;
        
        let scaleRatio = 2
        
        for i in imageRowStart...(imageRowEnd - 1) {
            for j in imageRowStart...(imageColEnd - 1) {
                autoreleasepool({ () -> () in
                    let _i = i + offsetI
                    let _j = j + offsetJ
                    if _i < imageRowStart || _j < imageColStart || _i >= imageRowEnd || _j >= imageColEnd {
                        
                    } else {
                        let index = imageRow * j + i
                        let index4 = index * 4;
                        let _index = imageRow * _j + _i
                        let _index4 = _index * 4 // because there are 4 channels
                        var baseImagePixel = (Int(baseImagePixels[index4]) - thresholdBase) * scaleRatio + thresholdBase
                        baseImagePixel = max(min(baseImagePixel, maxBase), minBase) - averageBase
                        var imagePixel = (Int(imagePixels[_index4]) - thresholdBase) * scaleRatio + thresholdImage
                        imagePixel = max(min(imagePixel, maxImage), minImage) - averageImage
                        dotProduct += baseImagePixel * imagePixel
                        baseDotProduct += baseImagePixel * baseImagePixel
                        imageDotProduct += imagePixel * imagePixel
                    }
                })
            }
        }
        
        return Float(dotProduct) / sqrt(Float(baseDotProduct) * Float(imageDotProduct))
    }
    
    static func cropCGImageAndGetCGImage(image: CGImageRef) -> CGImageRef {
        let sampleArea = Preference.getSampleArea()
        
        let width = CGImageGetWidth(image)
        let height = CGImageGetHeight(image)
        
        let imageXStart = Int(width) * sampleArea[0] / 100
        let imageXEnd = Int(width) * sampleArea[1] / 100 + 1
        let imageYStart = Int(height) * sampleArea[2] / 100
        let imageYEnd = Int(height) * sampleArea[3] / 100 + 1
        
        let posX: CGFloat = CGFloat(imageXStart)
        let posY: CGFloat = CGFloat(imageYStart)
        let cgwidth: CGFloat = CGFloat(imageXEnd - imageXStart - 1)
        let cgheight: CGFloat = CGFloat(imageYEnd - imageYStart - 1)
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image, rect)!
        
        return imageRef
    }
}
