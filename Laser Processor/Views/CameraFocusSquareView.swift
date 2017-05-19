//
//  CameraFocusSquareView.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 25/4/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import QuartzCore

class CameraFocusSquareView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = 2.0
        self.layer.borderColor = UIColor.yellowColor().CGColor
        
        let selectionAnimation = CABasicAnimation(keyPath: "borderColor")
        selectionAnimation.toValue = UIColor.whiteColor().CGColor
        selectionAnimation.repeatCount = 3
        self.layer.addAnimation(selectionAnimation, forKey: "selectionAnimation")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
