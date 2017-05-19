//
//  CameraView.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 25/4/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit

class CameraView: UIView {
    
    weak var delegate: CameraViewDelegate!
    var cameraFocusSquareView: CameraFocusSquareView?

    init(frame: CGRect, delegate: CameraViewDelegate) {
        super.init(frame: frame)
        
        self.delegate = delegate
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CameraView.focus))
        let panGestureRegognizer = UIPanGestureRecognizer(target: self, action: #selector(CameraView.swiped))
//        self.addGestureRecognizer(tapGestureRecognizer)
        self.addGestureRecognizer(panGestureRegognizer)
        
    }
    
    func initSampleArea() {
        let sampleArea = Preference.getSampleArea()
        let x0 = self.frame.width * (CGFloat)(sampleArea[0]) / 100.0
        let x1 = self.frame.width * (CGFloat)(sampleArea[1]) / 100.0
        let y0 = self.frame.height * (CGFloat)(sampleArea[2]) / 100.0
        let y1 = self.frame.height * (CGFloat)(sampleArea[3]) / 100.0
        
        let sampleRect = CGRectMake(x0, y0, x1 - x0, y1 - y0)
        let cameraSampleAreaSquareView = CameraSampleAreaSquareView(frame: sampleRect)
        self.addSubview(cameraSampleAreaSquareView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var startLocation = CGPoint()
    func swiped(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            startLocation = recognizer.locationInView(self)
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            let stopLocation = recognizer.locationInView(self)
            let dx = stopLocation.x - startLocation.x
            let dy = stopLocation.y - startLocation.y
            self.delegate.cameraViewFocusChanged(dy)
            self.delegate.cameraViewExposureChanged(dx)
            startLocation = recognizer.locationInView(self)
        }
        
//        if cameraFocusSquareView != nil {
//            cameraFocusSquareView?.removeFromSuperview()
//            cameraFocusSquareView = nil
//        }
//        
//        cameraFocusSquareView = CameraFocusSquareView(frame: CGRectMake(position.x - 40, position.y - 40, 80, 80))
//        self.addSubview(cameraFocusSquareView!)
//        cameraFocusSquareView?.setNeedsDisplay()
//        
//        let focusPoint = CGPointMake(position.x / self.frame.width, position.y / self.frame.height)
//        self.delegate.cameraViewFocused(focusPoint)
    }
}


protocol CameraViewDelegate: class {
    
    func cameraViewFocusChanged(deltaValue: CGFloat)
    func cameraViewExposureChanged(deltaValue: CGFloat)
    
}