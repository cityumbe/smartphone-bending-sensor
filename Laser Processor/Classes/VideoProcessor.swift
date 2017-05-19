//
//  VideoProcessor.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 2/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import AVFoundation

@objc class VideoProcessor: NSObject, CalculationManagerDelegate {

    var videoAsset: AVAsset!
    let calculationManager = CalculationManager()
    
    var progressHandler:((Int)->Void)!
    var completeHandler:((Int)->Void)!
    
    init(videoAsset: AVAsset) throws {
        super.init()
        
        self.videoAsset = videoAsset
        do {
            try printVideoMetaData()
        } catch {
            throw error
        }
        
        self.calculationManager.delegate = self
        self.calculationManager.setResourceAllocationScheme(.LowMemoryUsage)
    }
    
    func printVideoMetaData() throws {
        let videoTracks = self.videoAsset.tracksWithMediaType(AVMediaTypeVideo)
        guard videoTracks.count > 0 else {
            throw NSError(domain: "No video track found in this video", code: 0, userInfo: nil)
        }
        let videoTrack = videoTracks[0]
        let durationSeconds = CMTimeGetSeconds(self.videoAsset.duration)
        let timePerFrame = 1.0 / Float(videoTrack.nominalFrameRate)
        let totalFrames = Float(durationSeconds) * Float(videoTrack.nominalFrameRate)
    
        print("Duration: \(durationSeconds) sec");
        print("Nominal Frame Rate: \(timePerFrame)");
        print("Frame Number: \(roundf(totalFrames))");
    }
    
    func getThumbnail() -> CGImageRef? {
        
        let videoTracks = self.videoAsset.tracksWithMediaType(AVMediaTypeVideo)
        print("there are \(videoTracks.count) video tracks")
        
        let imageGenerator = AVAssetImageGenerator(asset: self.videoAsset)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(2, 600)
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(2, 600)
        
        let duration = self.videoAsset.duration
        
        do {
            var estimatedTime = duration
            estimatedTime.value = 0
            var actualTime = CMTime()
            
            let image = try imageGenerator.copyCGImageAtTime(estimatedTime, actualTime: &actualTime)
            
            return image
        } catch {
            print("Image generation error: \(error)")
            return nil
        }
    }
    
    func process(progressHandler: (Int)->Void, completeHandler: (Int)->Void, frameHandler: ((CGImageRef)->Void)?) {
        self.progressHandler = progressHandler
        self.completeHandler = completeHandler
        
        let videoTracks = self.videoAsset.tracksWithMediaType(AVMediaTypeVideo)
        print("there are \(videoTracks.count) video tracks")
        let videoTrack = videoTracks[0]
        let durationSeconds = CMTimeGetSeconds(self.videoAsset.duration)
        let totalFrames = Float64(durationSeconds) * Float64(videoTrack.nominalFrameRate)
        let timePerFrame = 1.0 / Float(videoTrack.nominalFrameRate)
        totalFrameCount = Int(floor(totalFrames))
        
        let imageGenerator = AVAssetImageGenerator(asset: self.videoAsset)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(2, 600)
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(2, 600)
        
        let date = NSDate()
        
        let duration = self.videoAsset.duration
        
        for counter in 0...totalFrameCount - 1 {
            autoreleasepool({ () -> () in
                var actualTime = CMTime()
                
                var estimatedTime = duration
                estimatedTime.value = estimatedTime.value * Int64(counter) / Int64(totalFrames)
                
                do {
                    var image = try imageGenerator.copyCGImageAtTime(estimatedTime, actualTime: &actualTime)
                    
                    image = Algorithm.cropCGImageAndGetCGImage(image)
                    
                    print("\(estimatedTime.value)/\(estimatedTime.timescale) \(actualTime.value)/\(actualTime.timescale)=\(actualTime.seconds)")
                    
                    let shiftedDate = date.dateByAddingTimeInterval(Double(timePerFrame) * Double(counter))
                    print("CGImageGetWidth = \(CGImageGetWidth(image))")
                    frameHandler?(image)
                    calculationManager.addImage(image, timeMayNil: shiftedDate)
                } catch {
                    print("Image generation error: \(error)")
                }
            })
        }
        
        calculationManager.commit()
    }
    
    var totalFrameCount = 0
    var lastPercentage = -1
    
    func calculationManagerCorrelationCalculated(calculationManager: CalculationManager, correlation: Double) {
        let percentage = calculationManager.imageCorrelations.count * 100 / (totalFrameCount - calculationManager.baseImageGap)
        if lastPercentage != percentage {
            progressHandler(percentage)
            lastPercentage = percentage
        }
    }
    
    func calculationManagerAllCorrelationCalculated(calculationManager: CalculationManager, count: Int) {
        completeHandler(count)
    }
}
