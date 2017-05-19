//
//  DataSetImage.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 20/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import Foundation

class DataSetImage {

    var id: Int64!
    var dataSetId: Int64!
    var isBaseImage: Bool!
    var correlation: Double?
    var createdTime: NSDate!
    
    init(id: Int64, dataSetId: Int64, isBaseImage: Bool, correlation: Double?, createdTime: NSDate) {
        self.id = id
        self.dataSetId = dataSetId
        self.isBaseImage = isBaseImage
        self.correlation = correlation
        self.createdTime = createdTime
    }
    
}
