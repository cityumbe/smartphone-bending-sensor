//
//  CaptureViewController.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 19/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import AVFoundation
import VBFPopFlatButton
import PKHUD

class CaptureViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CalculationManagerDelegate, CameraViewDelegate {

    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var captureVideoPreviewLayer:AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice?
    var cameraView: CameraView!
    
    @IBOutlet weak var plotView: PlotView!
    @IBOutlet weak var plotViewBackgroundView: UIView!
    
    let calculationManager = CalculationManager()
    
    var timer: NSTimer?
    var addedImageCount = 0
    
    var algorithm: Algorithm!
    // MARK: -viewDid** and outlets
    
    @IBOutlet weak var buttomBarView: UIView!
    var controlButton: VBFPopFlatButton?
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var countDownLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        configureVideoCapture()
        addVideoPreviewLayer()
        
        configureButtons()
        
        super.viewDidLoad()
        
        if Preference.getCalculationDevice() == "GPU" {
            algorithm = Algorithm()
        }
        
        plotViewBackgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        plotView.initPlot()
        plotViewBackgroundView.hidden = true
        
        self.calculationManager.delegate = self
        if Preference.effectivePlotModeOn() {
            self.calculationManager.setResourceAllocationScheme(.HighUserInteractive)
        }
        
        setShouldSave(.NotStart)
    }
    
    override func viewWillDisappear(animated: Bool) {
        captureSession.stopRunning()
    }
    
    override func viewDidAppear(animated: Bool) {
        captureSession.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    // MARK: - setup views
    
    func configureVideoCapture() {
        let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.Back }
        if let captureDevice = devices.first as? AVCaptureDevice  {
            self.captureDevice = captureDevice
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                try captureDevice.lockForConfiguration()
                captureDevice.focusMode = .AutoFocus
                captureDevice.unlockForConfiguration()
            } catch {
                print("Error: \(error)")
                let alertController = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            captureSession.sessionPreset = Preference.getPhotoResolutionAsPreset()
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
        }
    }
    
    func addVideoPreviewLayer() {
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            previewLayer.bounds = view.bounds
            previewLayer.position = CGPointMake(view.bounds.size.width / 2, view.bounds.size.width * 2 / 3)
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
            cameraView = CameraView(frame: CGRectMake(0.0, 0.0, view.bounds.size.width, view.bounds.size.width * 4 / 3), delegate: self)
            cameraView.layer.addSublayer(previewLayer)
            cameraView.initSampleArea()
            view.addSubview(cameraView)
            view.sendSubviewToBack(cameraView)
        }
    }
    
    func configureButtons() {
        self.controlButton = VBFPopFlatButton(frame: CGRectMake(0, 0, 40, 40), buttonType: .buttonRightTriangleType, buttonStyle: .buttonRoundedStyle, animateToInitialState: true)
        self.controlButton?.roundBackgroundColor = UIColor.whiteColor()
        self.controlButton?.lineThickness = 3
        self.controlButton?.lineRadius = 1
        self.controlButton?.tintColor = UIColor.blackColor()
        self.controlButton?.addTarget(self, action: #selector(CaptureViewController.startCapture), forControlEvents: .TouchUpInside)
        self.controlButton?.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [NSLayoutConstraint(item: self.controlButton!, attribute: .CenterX, relatedBy: .Equal, toItem: self.buttomBarView, attribute: .CenterX, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: self.controlButton!, attribute: .CenterY, relatedBy: .Equal, toItem: self.buttomBarView, attribute: .CenterY, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: self.controlButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40), NSLayoutConstraint(item: self.controlButton!, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40)]
        
        self.buttomBarView.addSubview(self.controlButton!)
        self.buttomBarView.addConstraints(constraints)
        self.buttomBarView.layoutSubviews()
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.timer?.invalidate()
        self.timer = nil
        DataSetManager.clearCacheImages()
        self.calculationManager.clean()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    // MARK: - capture methods
    func updateStatusLabel() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            assert(NSThread.isMainThread())
            self.statusLabel.text = "overhead (\(self.calculationManager.baseImages.count)) + \(self.calculationManager.imageCorrelations.count)/\(self.calculationManager.imageCount)"
        })
    }
    
    func capture() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.controlButton?.animateToType(.buttonOkType)
        })
        
        assert(NSThread.isMainThread())
        
        if self.calculationManager.imageCount >= Preference.getImageCount() {
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.controlButton?.animateToType(.buttonPausedType)
                self.updateStatusLabel()
            })
            finishCapture(self)
            return
        }
        
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                if error != nil {
                    print("Photo taking error: \(error)")
                    return
                }
                
                // double check
                if self.calculationManager.imageCount >= Preference.getImageCount() {
                    return
                }
                
                // if paused, not continue
                if self.isPaused() {
                    return
                }
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                
                // save image to memory
                let image = UIImage(data: imageData)!.fixOrientationToUp()!
                self.calculationManager.addImage(self.cropImageAndGetCGImage(image), timeMayNil: nil)
                
                if self.calculationManager.imageCount == Preference.getImageCount() {
                    self.calculationManager.commit()
                }
                
                // change button state and label text
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.controlButton?.animateToType(.buttonPausedType)
                    self.updateStatusLabel()
                })
            }
        }
    }
    
    private func cropImageAndGetCGImage(image: UIImage) -> CGImageRef {
        let contextImage = UIImage(CGImage: image.CGImage!)
        
        return Algorithm.cropCGImageAndGetCGImage(image.CGImage)
    }
    
    private func isPaused() -> Bool {
        return self.timer == nil
    }
    
    func startCapture() {

        // show plot view
        if plotViewBackgroundView.hidden {
            plotViewBackgroundView.hidden = false
        }
        
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
            self.calculationManager.commit()
            return
        }
        
        let countDownTime = Int(ceil(Double(Preference.getStartButtonDelay()) / 1000.0))
        setCountDown(countDownTime) { () -> Void in
            self.setShouldSave(.Processing)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                do {
                    try self.captureDevice?.lockForConfiguration()
                    self.captureDevice?.focusMode = .Locked
                    self.captureDevice?.unlockForConfiguration()
                } catch {
                    print("Error: \(error)")
                }
                
                self.timer = NSTimer.scheduledTimerWithTimeInterval(Preference.getShootingIntervalAsSeconds(), target: self, selector: #selector(CaptureViewController.capture), userInfo: nil, repeats: true)
                
                assert(NSThread.isMainThread())
            })
        }
    }

    @IBAction func finishCapture(sender: AnyObject) {
        if self.calculationManager.imageCount == 0 {
            self.dismiss(self)
            return
        }
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        if self.calculationManager.imageCount != self.calculationManager.imageCorrelations.count {
            return
        }
        
        let alertController = UIAlertController(title: "Save Data Set", message: "Data Set Name: ", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            textField.text = "Untitled Data Set \(dateFormatter.stringFromDate(NSDate()))"
            textField.clearButtonMode = .WhileEditing
        }
        alertController.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            
            assert(NSThread.isMainThread())
            
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Saving...")
            PKHUD.sharedHUD.show()
            
            NSOperationQueue().addOperationWithBlock({ () -> Void in
                DataSetManager().saveDataSet(alertController.textFields![0].text!, calculationManager: self.calculationManager)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    PKHUD.sharedHUD.hide()
                    self.dismissViewControllerAnimated(true, completion: nil)
                    assert(NSThread.isMainThread())
                })
            })
            
        }))
        assert(NSThread.isMainThread())
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - count down
    var countDownTime: Int!
    var countDownHandler: (()->Void)!
    var countDownTimer: NSTimer?
    
    func setCountDown(second: Int, handler: (()->Void)) {
        countDownTime = second
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.countDownLabel.text = "\(self.countDownTime)"
            self.countDownLabel.hidden = false
        }
        countDownHandler = handler
        
        // remove previous count timer if exists
        if countDownTimer != nil {
            countDownTimer?.invalidate()
            countDownTimer = nil
        }
        countDownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CaptureViewController.countDown), userInfo: nil, repeats: false)
    }
    
    func countDown() {
        if countDownTime == 0 {
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.countDownLabel.hidden = true
            }
        }
        countDownTime = countDownTime - 1
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.countDownLabel.text = "\(self.countDownTime)"
        }
        if countDownTime == 0 {
            countDownHandler()
        }
        countDownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CaptureViewController.countDown), userInfo: nil, repeats: false)
    }
    
    enum State {
        case NotStart
        case Processing
        case Finished
    }
    
    func setShouldSave(state: State) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            switch state {
            case .NotStart:
                self.activityIndicator.hidden = true
                self.saveButton.hidden = true
            case .Processing:
                self.activityIndicator.hidden = false
                self.saveButton.hidden = true
            case .Finished:
                self.activityIndicator.hidden = true
                self.saveButton.hidden = false
            }
        }
    }
    
    // MARK: CalculationManagerDelegate
    func calculationManagerCorrelationCalculated(calculationManager: CalculationManager, correlation: Double) {
        plotView.addCorrelation(correlation)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.updateStatusLabel()
        }
    }
    
    func calculationManagerAllCorrelationCalculated(calculationManager: CalculationManager, count: Int) {
        print("Calculation finished")
        setShouldSave(.Finished)
    }
    
    // MARK: - CameraViewDelegate methods
//    func cameraViewFocused(focusPoint: CGPoint) {
//        do {
//            try captureDevice?.lockForConfiguration()
//            captureDevice?.focusPointOfInterest = focusPoint
//            print("try to focus on \(focusPoint)")
//            captureDevice?.focusMode = .AutoFocus
//            captureDevice?.unlockForConfiguration()
//        } catch {
//            print("Cannot focus camera: \(error)")
//        }
//    }
    func cameraViewFocusChanged(deltaValue: CGFloat) {
        do {
            try captureDevice?.lockForConfiguration()
            captureDevice?.focusMode = .Locked
            var lensPosition = captureDevice!.lensPosition
            lensPosition = lensPosition + Float(deltaValue) / 100.0
            lensPosition = min(max(0.0, lensPosition), 1.0)
            captureDevice?.setFocusModeLockedWithLensPosition(lensPosition, completionHandler: nil)
            print("try to focus on lensPosition: \(lensPosition)")
            captureDevice?.unlockForConfiguration()
        } catch {
            print("Cannot focus camera: \(error)")
        }
    }
    
    func cameraViewExposureChanged(deltaValue: CGFloat) {
        do {
            try captureDevice?.lockForConfiguration()
            captureDevice?.exposureMode = .Locked
            var exposureTargetBias = captureDevice!.exposureTargetBias
            exposureTargetBias = exposureTargetBias + Float(deltaValue) / 100.0
//            exposureTargetBias = min(max(0.0, exposureTargetBias), 1.0)
            captureDevice?.setExposureTargetBias(exposureTargetBias, completionHandler: nil)
            print("try to set exposureTargetBias: \(exposureTargetBias)")
            captureDevice?.unlockForConfiguration()
        } catch {
            print("Cannot focus camera: \(error)")
        }
    }
}
