//
//  DataSet.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 20/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import Foundation

class DataSet {
    var name: String!
    var numberOfImages: Int!
    var createdTime: NSDate!
    var id: Int64!
    
    init(id: Int64, name: String, numberOfImages: Int, createdTime: NSDate) {
        self.id = id
        self.name = name
        self.numberOfImages = numberOfImages
        self.createdTime = createdTime
    }
}
