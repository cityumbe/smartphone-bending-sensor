//
//  CameraSampleAreaSquareView.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 25/4/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit

class CameraSampleAreaSquareView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 2.0
        self.layer.borderColor = UIColor.blueColor().CGColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
