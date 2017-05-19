//
//  DataSetManager.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 19/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

@objc class DataSetManager: NSObject {

    static let imageDir = "images"
    static let cacheDir = "tmp"
    
    static func writeImageToFile(image: CGImageRef, path: String) {
        #if os(iOS) || os(watchOS) || os(tvOS)
            let uiImage = UIImage(CGImage: image)
            UIImagePNGRepresentation(uiImage)?.writeToFile(path, atomically: true)
        #elseif os(OSX)
            let bitmapRep = NSBitmapImageRep(CGImage: image)
            do {
                try bitmapRep.representationUsingType(.NSPNGFileType, properties: [String: AnyObject]())?.writeToFile(path, options: .AtomicWrite)
            } catch {
                print("\(error)")
            }
        #endif
    }
    
    static func docsDirPath() -> String {
        #if os(iOS) || os(watchOS) || os(tvOS)
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return dirPaths[0]
        #elseif os(OSX)
            return "/Users/Hung/Desktop/lp"
        #endif
    }
    
    static func imagesDirPath() -> String {
        return "\(docsDirPath())/\(imageDir)"
    }
    
    static func cacheDirPath() -> String {
        return "\(docsDirPath())/\(cacheDir)"
    }
    
    static func cacheImage(image: CGImageRef) -> String {
        
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(cacheDirPath()) {
            do {
                try fileManager.createDirectoryAtPath(cacheDirPath(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: \(error)")
            }
        }
        
        let cacheImagePath = "\(cacheDirPath())/\(arc4random_uniform(600000000))-\(arc4random_uniform(400)).png"
        
        writeImageToFile(image, path: cacheImagePath)
        
        return cacheImagePath
    }
    
    static func clearCacheImages() {
        let fileManager = NSFileManager.defaultManager()
        do {
            let cacheFiles = try fileManager.contentsOfDirectoryAtPath(cacheDirPath())
            var count = 1
            for cacheFile in cacheFiles {
                print("Removing cache file (\(count)/\(cacheFiles.count)): \(cacheFile)")
                try fileManager.removeItemAtPath("\(cacheDirPath())/\(cacheFile)")
                count = count + 1
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
#if os(iOS) || os(watchOS) || os(tvOS)
    static let dbFile = "laser_v1.0.json"
    
    let dbFilePath = "\(DataSetManager.docsDirPath())/\(DataSetManager.dbFile)"
    
    var dataBase: LDataBase!
    
    override init() {
        let jsonString = NSString(contentsOfFile: dbFilePath, encoding: NSUTF8StringEncoding)
    }
    
    func numberOfDataSets() -> Int {
        return
    }
    
    func saveDataSet(dataSetName: String, baseImages: [CGImageRef], baseImageCreatedTime: NSDate, cacheImagePaths: [String], imageCorrelations: [Double], imageCreatedTimes: [NSDate]) {
        // insert DataSet
        let dataSetInsert = dataSet.insert(name <- dataSetName, numberOfImages <- Int64(cacheImagePaths.count), createTime <- NSDate())
        var dataSetId: Int64!
        do {
            let rowId = try db.run(dataSetInsert)
            for row in try db.prepare(dataSet.filter(rowid == rowId)) {
                dataSetId = row[id]
            }
        } catch {
            print("Error: \(error)")
        }
        
        let dataSetPath = "\(DataSetManager.imagesDirPath())/\(dataSetId)"
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(dataSetPath) {
            do {
                try fileManager.createDirectoryAtPath(dataSetPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: \(error)")
            }
        }
        
        // insert images
        for i in 0...(cacheImagePaths.count - 1) {
            let imageInsert = self.image.insert(self.dataSetId <- dataSetId, crossCorrelation <- imageCorrelations[i], isBaseImage <- 0, createTime <- imageCreatedTimes[i])
            var imageId: Int64!
            do {
                let rowId = try db.run(imageInsert)
                for row in try db.prepare(self.image.filter(rowid == rowId)) {
                    imageId = row[id]
                }
                let imagePath = "\(dataSetPath)/\(imageId).png"
                let cacheImagePath = cacheImagePaths[i]
                try fileManager.moveItemAtPath(cacheImagePath, toPath: imagePath)
            } catch {
                print("Error: \(error)")
            }
        }
        
        // insert baseimage
        for i in 0...(baseImages.count - 1) {
            let imageInsert = self.image.insert(self.dataSetId <- dataSetId, crossCorrelation <- imageCorrelations[i], isBaseImage <- 1, createTime <- imageCreatedTimes[i])
            var imageId: Int64!
            do {
                let rowId = try db.run(imageInsert)
                for row in try db.prepare(self.image.filter(rowid == rowId)) {
                    imageId = row[id]
                }
                let imagePath = "\(dataSetPath)/\(imageId).png"
                DataSetManager.writeImageToFile(baseImages[i], path: imagePath)
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func saveDataSetFromCalculationManager(dataSetName: String, calculationManager: CalculationManager) {
        DataSetManager().saveDataSet(dataSetName, baseImages: calculationManager.baseImages, baseImageCreatedTime: calculationManager.baseImageTookTime!, cacheImagePaths: calculationManager.imageCachePaths, imageCorrelations: calculationManager.imageCorrelations, imageCreatedTimes: calculationManager.imageTookTimes)
    }
    
    func fetchAllDataSets() -> [DataSet] {
        var dataSets = [DataSet]()
        do {
            for row in try db.prepare(self.dataSet.select(id, name, createTime, numberOfImages)) {
                dataSets.append(DataSet(id: row[id], name: row[name]!, numberOfImages: Int(row[numberOfImages]), createdTime: row[createTime]))
            }
        } catch {
            print("Error: \(error)")
        }
        return dataSets.reverse()
    }
    
    func fetchAllImages(dataSetId: Int64) -> (baseImages: [DataSetImage], images: [DataSetImage]) {
        var baseImages = [DataSetImage]()
        var images = [DataSetImage]()
        
        do {
            for row in try db.prepare(self.image.select(id, self.dataSetId, isBaseImage, crossCorrelation, createTime).filter(self.dataSetId == dataSetId)) {
                if row[isBaseImage] > 0 {
                    baseImages.append(DataSetImage(id: row[id], dataSetId: dataSetId, isBaseImage: true, correlation: nil, createdTime: row[createTime]))
                } else {
                    images.append(DataSetImage(id: row[id], dataSetId: dataSetId, isBaseImage: false, correlation: row[crossCorrelation], createdTime: row[createTime]))
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return (baseImages, images)
    }

    func deleteDataSet(dataSetId: Int64) {
        do {
            try db.run(dataSet.filter(id == dataSetId).delete())
            try db.run(image.filter(self.dataSetId == dataSetId).delete())
            let dataSetPath = "\(DataSetManager.imagesDirPath())/\(dataSetId)"
            try NSFileManager.defaultManager().removeItemAtPath(dataSetPath)
        } catch {
            print("Error: \(error)")
        }
    }
#elseif os(OSX)
    @nonobjc func saveDataSet(baseImages: [CGImageRef], baseImageCreatedTime: NSDate, cacheImagePaths: [String], imageCorrelations: [Double], imageCreatedTimes: [NSDate]) {
        
        let dataSetPath = "\(DataSetManager.imagesDirPath())/"
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(dataSetPath) {
            do {
                try fileManager.createDirectoryAtPath(dataSetPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: \(error)")
            }
        }
        
        // insert images
        for i in 0...(cacheImagePaths.count - 1) {
            do {
                let imagePath = "\(dataSetPath)/i\(i).png"
                let cacheImagePath = cacheImagePaths[i]
                try fileManager.moveItemAtPath(cacheImagePath, toPath: imagePath)
            } catch {
                print("Error: \(error)")
            }
        }
        
        // insert baseimage
        for i in 0...(baseImages.count - 1) {
            do {
                let imagePath = "\(dataSetPath)/b\(i).png"
                DataSetManager.writeImageToFile(baseImages[i], path: imagePath)
            } catch {
                print("Error: \(error)")
            }
        }
        
        // write correlations
        let correlationPath = "\(dataSetPath)/correlations.dat"
        var string = ""
        for imageCorrelation in imageCorrelations {
            string = string.stringByAppendingString("\(imageCorrelation)\n")
        }
        do {
            try string.writeToFile(correlationPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func saveDataSet(calculationManager: CalculationManager) {
        DataSetManager().saveDataSet(calculationManager.baseImages, baseImageCreatedTime: calculationManager.baseImageTookTime!, cacheImagePaths: calculationManager.imageCachePaths, imageCorrelations: calculationManager.imageCorrelations, imageCreatedTimes: calculationManager.imageTookTimes)
    }
#endif
}

class LDataBase {
    var dataSets: [LDataSet]!
    var lastDataSetId: Int = 0
    
    init(json: [String: AnyObject]?) {
        guard let json = json else {
            dataSets = [LDataSet]()
        }
        lastDataSetId = json["last-dataset-id"] as! Int
        
        dataSets = [LDataSet]()
        for j in json["datasets"] as! [[String: AnyObject]] {
            dataSets.append(LDataSet(json: j))
        }
    }
    
    func toJSONString() -> String {
        var dataSetJSONStrings = [String]()
        for dataSet in dataSets {
            dataSetJSONStrings.append(dataSet.toJSONString())
        }
        
        return "{\"last-dataset-id\": \(lastDataSetId), \"datasets\": [\(dataSetJSONStrings.joinWithSeparator(", "))]}"
    }
}

class LDataSet {
    var id: Int!
    var name: String!
    var baseImages: [LImage]!
    var images: [LImage]!
    
    init(id: Int!, name: String!) {
        self.id = id
        self.name = name
    }
    
    init(json: [String: AnyObject]) {
        id = json["id"] as! Int
        name = json["name"] as! String
        
        baseImages = [LImage]()
        for j in json["base-images"] as! [[String: AnyObject]] {
            baseImages.append(LImage(json: j))
        }
        
        images = [LImage]()
        for j in json["images"] as! [[String: AnyObject]] {
            images.append(LImage(json: j))
        }
    }
    
    func toJSONString() -> String {
        var baseImageJSONStrings = [String]()
        for baseImage in baseImages {
            baseImageJSONStrings.append(baseImage.toJSONString())
        }
        
        var imageJSONStrings = [String]()
        for image in images {
            imageJSONStrings.append(image.toJSONString())
        }
        
        return "{\"id\": \(id), \"name\": \(name), \"base-images\": [\(baseImageJSONStrings.joinWithSeparator(", "))], \"images\": [\(imageJSONStrings.joinWithSeparator(", "))]}"
    }
}

class LImage {
    var id: Int!
    var correlation: Double?
    
    func isBaseImage() -> Bool {
        return correlation == nil
    }
    
    init(id: Int!, correlation: Double?) {
        self.id = id
        self.correlation = correlation
    }
    
    init(json: [String: AnyObject?]) {
        id = json["id"] as! Int
        if let correlation = json["correlation"] {
            self.correlation = correlation as? Double
        }
    }
    
    func toJSONString() -> String {
        if isBaseImage() {
            return "{\"id\": \(id), \"correlation\": \(correlation)}"
        } else {
            return "{\"id\": \(id)}"
        }
    }
}
