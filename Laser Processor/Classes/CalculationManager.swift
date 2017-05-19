//
//  CalculationManager.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 2/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import Foundation

class CalculationManager: NSObject {
    
    weak var delegate: CalculationManagerDelegate?
    
    let baseImageGap = Preference.getBaseImageGap()
    @nonobjc var baseImages = [CGImageRef]() // save first baseImageGap baseImages
    let baseImageQueue = Queue<CGImageRef>()
    var baseImageTookTime: NSDate?
    var imageCount = 0
    var imageCachePaths = [String]()
    var imageTookTimes = [NSDate]()
    var imageCorrelations = [Double]()
    
    var addedImageCount = 0
    
    var algorithm: Algorithm!
    
    let calculationOperationQueue = NSOperationQueue()
    let cacheOperationQueue = NSOperationQueue()
    
    override init() {
        super.init()
        
        if Preference.getCalculationDevice() == "GPU" {
            algorithm = Algorithm()
        }
        
        // one job a time, prevent race condition
        calculationOperationQueue.maxConcurrentOperationCount = 1
        cacheOperationQueue.maxConcurrentOperationCount = 1
    }
    
    func setResourceAllocationScheme(resourceAllocationScheme: ResourceAllocationScheme) {
        self.resourceAllocationScheme = resourceAllocationScheme
        switch resourceAllocationScheme {
        case .HighUserInteractive:
            calculationOperationQueue.qualityOfService = .UserInitiated
            cacheOperationQueue.qualityOfService = .Default
        case .LowMemoryUsage:
            break
        case .Default:
            calculationOperationQueue.qualityOfService = .Default
            cacheOperationQueue.qualityOfService = .Default
        }
    }
    
    enum ResourceAllocationScheme {
        case Default
        case HighUserInteractive
        case LowMemoryUsage // single thread, pipeline job
    }
    
    var resourceAllocationScheme = ResourceAllocationScheme.Default
    
    // pass time == nil will use NOW as time
    func addImage(image: CGImageRef, timeMayNil: NSDate?) {
        
        var time: NSDate!
        
        if timeMayNil == nil {
            time = NSDate()
        } else {
            time = timeMayNil!
        }
        
        if baseImages.count < baseImageGap {
            if !Preference.absoluteMeasurementOn() {
                baseImageQueue.enqueue(image)
            }
            baseImages.append(image)
            baseImageTookTime = time
        } else {
            imageCount = imageCount + 1
            imageTookTimes.append(time)
            addedImageCount = addedImageCount + 1
            var baseImage: CGImageRef
            if Preference.absoluteMeasurementOn() {
                baseImage = baseImages[0]
            } else {
                baseImage = baseImageQueue.dequeue()!
                baseImageQueue.enqueue(image)
            }
            if resourceAllocationScheme == .LowMemoryUsage {
                self.processImageData(image, baseImage: baseImage)
            } else {
                self.calculationOperationQueue.addOperationWithBlock({ () -> Void in
                    self.processImageData(image, baseImage: baseImage)
                })
            }
        }
        
    }
    
    // no more images coming
    func commit() {
        self.calculationOperationQueue.addOperationWithBlock({ () -> Void in
            // notify finished
            self.cacheOperationQueue.waitUntilAllOperationsAreFinished()
            self.delegate?.calculationManagerAllCorrelationCalculated(self, count: self.imageCorrelations.count + self.baseImageGap)
            self.clean()
        })
    }
    
    func clean() {
        calculationOperationQueue.cancelAllOperations()
        cacheOperationQueue.cancelAllOperations()
    }
    
    func processImageData(image: CGImageRef, baseImage: CGImageRef) {
        let correlation = crossCorrelation(image, baseImage: baseImage)
        
        cacheOperationQueue.addOperationWithBlock({ () -> Void in
            self.imageCachePaths.append(DataSetManager.cacheImage(image))
        })
        
        imageCorrelations.append(correlation)
        
        // call delegate method
        self.delegate?.calculationManagerCorrelationCalculated(self, correlation: correlation)
    }
    
    // MARK: - calculation method
    func crossCorrelation(image: CGImageRef, baseImage: CGImageRef) -> Double {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image))
        let imagePixels = UnsafeMutablePointer<UInt8>(CFDataGetBytePtr(pixelData))
        
        let basePixelData = CGDataProviderCopyData(CGImageGetDataProvider(baseImage))
        let baseImagePixels = UnsafeMutablePointer<UInt8>(CFDataGetBytePtr(basePixelData))
        
        let baseImageRow = CGImageGetWidth(baseImage)
        let baseImageCol = CGImageGetHeight(baseImage)
        let imageRow = CGImageGetWidth(image)
        let imageCol = CGImageGetHeight(image)
        
        assert(baseImageRow == imageRow)
        assert(baseImageCol == imageCol)
        
        var correlation: Double = 0.0
        
        if Preference.getCalculationDevice() == "GPU" {
            correlation = Double(algorithm.microShiftInnerProductGPU(baseImagePixels, imagePixels: imagePixels, imageRow: imageRow, imageCol: imageCol, maxOffset: Preference.getMaxShifting()))
        } else if Preference.getCalculationDevice() == "OpenCV" {
            correlation = Double(OpenCVWrapper.microShiftInnerProductGPU(baseImagePixels, imagePixels: imagePixels, imageRow: Int32(imageRow), imageCol: Int32(imageCol), maxShift: Int32(Preference.getMaxShifting())))
        } else {
            correlation = Double(Algorithm.microShiftInnerProduct(baseImagePixels, imagePixels: imagePixels, imageRow: imageRow, imageCol: imageCol, maxOffset: Preference.getMaxShifting()))
        }
        
        return correlation
    }
}
