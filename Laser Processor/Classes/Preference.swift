//
//  Preference.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 27/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import SwiftyUserDefaults
import AVFoundation

let startButtonDelayKey = DefaultsKey<Int?>("start-button-delay")
let baseImageGapKey = DefaultsKey<Int?>("base-image-gap")
let shootingIntervalKey = DefaultsKey<Int?>("shooting-interval")
let photoResolutionPresetKey = DefaultsKey<String?>("photo-resolution-preset")
let maxShiftingKey = DefaultsKey<Int?>("max-shifting")
let calculationDevicekey = DefaultsKey<String?>("calculation-device")
let imageCountKey = DefaultsKey<Int?>("image-count")
let sampleAreaKey = DefaultsKey<[Int]?>("sample-area")
let plotIntervalKey = DefaultsKey<Int?>("plot-interval")
let effectivePlotModeKey = DefaultsKey<Bool?>("effective-plot")
let channelKey = DefaultsKey<Int?>("channel")
let absoluteMeasurementKey = DefaultsKey<Bool?>("absolute-measure-mode")

class Preference: NSObject {
    class func getStartButtonDelay() -> Int {
        if let value = Defaults[startButtonDelayKey] {
            return value
        }
        Defaults[startButtonDelayKey] = 1000
        return getStartButtonDelay()
    }
    
    class func setStartButtonDelay(value: Int) {
        Defaults[startButtonDelayKey] = value
    }
    
    class func absoluteMeasurementOn() -> Bool {
        if let value = Defaults[absoluteMeasurementKey] {
            return value
        }
        Defaults[absoluteMeasurementKey] = true
        return absoluteMeasurementOn()
    }
    
    class func setAbsoluteMeasurement(value: Bool) {
        Defaults[absoluteMeasurementKey] = value
    }
    
    class func getBaseImageGap() -> Int {
        if Preference.absoluteMeasurementOn() {
            return 1
        }
        if let value = Defaults[baseImageGapKey] {
            return value
        }
        Defaults[baseImageGapKey] = 3
        return getBaseImageGap()
    }
    
    class func setBaseImageGap(value: Int) {
        Defaults[baseImageGapKey] = value
    }
    
    class func getImageCount() -> Int {
        if let value = Defaults[imageCountKey] {
            return value
        }
        Defaults[imageCountKey] = 100
        return getImageCount()
    }
    
    class func setImageCount(value: Int) {
        Defaults[imageCountKey] = value
    }
    
    class func getShootingInterval() -> Int {
        if let value = Defaults[shootingIntervalKey] {
            return value
        }
        Defaults[shootingIntervalKey] = 100
        return getShootingInterval()
    }
    
    class func setShootingInterval(value: Int) {
        Defaults[shootingIntervalKey] = value
    }
    
    class func getShootingIntervalAsSeconds() -> Double {
        let ms = Double(getShootingInterval())
        return ms / 1000.0
    }
    
    class func getPhotoResolution() -> String {
        if let value = Defaults[photoResolutionPresetKey] {
            return value
        }
        Defaults[photoResolutionPresetKey] = "Full Resolution"
        return getPhotoResolution()
    }
    
    class func setPhotoResolution(value: String) {
        Defaults[photoResolutionPresetKey] = value
    }
#if os(iOS) || os(watchOS) || os(tvOS)
    class func getPhotoResolutionAsPreset() -> String {
        let dict = ["Full Resolution": AVCaptureSessionPresetPhoto,
            "1920 x 1080": AVCaptureSessionPreset1920x1080, "1280 x 720": AVCaptureSessionPreset1280x720, "640 x 480": AVCaptureSessionPreset640x480]
        return dict[getPhotoResolution() as String]!
    }
#endif
    class func getMaxShifting() -> Int {
        if let value = Defaults[maxShiftingKey] {
            return value
        }
        Defaults[maxShiftingKey] = 0
        return getMaxShifting()
    }
    
    class func setMaxShifting(value: Int) {
        Defaults[maxShiftingKey] = value
    }
    
    class func getCalculationDevice() -> String {
        if let value = Defaults[calculationDevicekey] {
            return value
        }
        Defaults[calculationDevicekey] = "CPU"
        return getCalculationDevice()
    }
    
    class func setCalculationDevice(value: String) {
        Defaults[calculationDevicekey] = value
    }
    
    class func getSampleArea() -> [Int] {
        if let value = Defaults[sampleAreaKey] {
            return value
        }
        Defaults[sampleAreaKey] = [0, 100, 0, 100]
        return getSampleArea()
    }
    
    class func setSampleArea(value: [Int]) {
        Defaults[sampleAreaKey] = value
    }
    
    class func getPlotInterval() -> Int {
        if let value = Defaults[plotIntervalKey] {
            return value
        }
        Defaults[plotIntervalKey] = 10
        return getPlotInterval()
    }
    
    class func setPlotInterval(value: Int) {
        Defaults[plotIntervalKey] = value
    }
    
    class func effectivePlotModeOn() -> Bool {
        if let value = Defaults[effectivePlotModeKey] {
            return value
        }
        Defaults[effectivePlotModeKey] = false
        return effectivePlotModeOn()
    }
    
    class func setEffectivePlotMode(on: Bool) {
        Defaults[effectivePlotModeKey] = on
    }
    
    class func getChannel() -> Int {
        if let value = Defaults[channelKey] {
            return value
        }
        Defaults[channelKey] = 3
        return getChannel()
    }
    
    class func setChannel(value: Int) {
        Defaults[channelKey] = value
    }
}
