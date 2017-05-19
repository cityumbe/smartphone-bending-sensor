//
//  PreferenceViewController.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 26/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import XLForm
import AVFoundation

class PreferenceViewController: XLFormViewController {
    
    var toBeSaved = true
    
    override func viewDidLoad() {
        configureForm()
        
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        if !self.toBeSaved {
            return
        }
        
        // save the values
        let formValues = form.formValues()
        
        Preference.setStartButtonDelay(formValues["start-button-delay"] as! Int)
        Preference.setAbsoluteMeasurement(formValues["absolute-measure"] as! Bool)
        Preference.setBaseImageGap(formValues["base-images-gap"] as! Int)
        Preference.setImageCount(formValues["images-count"] as! Int)
        Preference.setShootingInterval(formValues["shooting-interval"] as! Int)
        Preference.setPhotoResolution(formValues["photo-resolution"] as! String)
        Preference.setMaxShifting(formValues["max-shifting"] as! Int)
        Preference.setCalculationDevice(formValues["calculation-device"] as! String)
        
        let sampleArea = [
            formValues["sample-area-x-0"] as! Int,
            formValues["sample-area-x-1"] as! Int,
            formValues["sample-area-y-0"] as! Int,
            formValues["sample-area-y-1"] as! Int
            ]
        Preference.setSampleArea(sampleArea)
        Preference.setPlotInterval(formValues["plot-interval"] as! Int)
        Preference.setEffectivePlotMode(formValues["effective-plot"] as! Bool)
        Preference.setChannel(["Red", "Green", "Blue", "Gray"].indexOf(formValues["channel"] as! String)!)
    }

    // MARK: -setup form
    
    func configureForm() {
        var form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Preferences") as XLFormDescriptor
        
        // Shutter Setting
        section = XLFormSectionDescriptor.formSectionWithTitle("Shutter Setting") as XLFormSectionDescriptor
        row = XLFormRowDescriptor(tag: "start-button-delay", rowType: XLFormRowDescriptorTypeStepCounter, title: "Start button delay (ms)")
        row.value = Preference.getStartButtonDelay()
        row.cellConfigAtConfigure.setObject(5000, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(1000, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(100, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "absolute-measure", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: "Absolute Measure")
        row.value = Preference.absoluteMeasurementOn()
        let absoluteMeasurementRow = row
        section.addFormRow(row)
        form.addFormSection(section)
        row = XLFormRowDescriptor(tag: "base-images-gap", rowType: XLFormRowDescriptorTypeStepCounter, title: "Base image gap")
        row.value = Preference.getBaseImageGap()
        row.cellConfigAtConfigure.setObject(30, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        row.hidden = "$\(absoluteMeasurementRow) = true"
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "images-count", rowType: XLFormRowDescriptorTypeStepCounter, title: "Image n")
        row.value = Preference.getImageCount()
        row.cellConfigAtConfigure.setObject(400, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "shooting-interval", rowType: XLFormRowDescriptorTypeStepCounter, title: "Shoot Interval (ms)")
        row.value = Preference.getShootingInterval()
        row.cellConfigAtConfigure.setObject(5000, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(10, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(10, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        section.footerTitle = "Base delay is the delay (ms) before taking the first base image"
        
        // Photo Setting
        form.addFormSection(section)
        
        section = XLFormSectionDescriptor.formSectionWithTitle("Photo Setting") as XLFormSectionDescriptor
        row = XLFormRowDescriptor(tag: "photo-resolution", rowType: XLFormRowDescriptorTypeSelectorPickerViewInline, title: "Resolution")
        row.value = Preference.getPhotoResolution()
        var options = ["Full Resolution", "1920 x 1080", "1280 x 720", "640 x 480"]
        row.selectorOptions = options
        section.addFormRow(row)
        section.footerTitle = "The resolution is constraint by shutter speed."
        
        form.addFormSection(section)
        
        // Calculation Settings
        section = XLFormSectionDescriptor.formSectionWithTitle("Calculation Setting") as XLFormSectionDescriptor
        row = XLFormRowDescriptor(tag: "max-shifting", rowType: XLFormRowDescriptorTypeStepCounter, title: "Max Shift (px)")
        row.value = Preference.getMaxShifting()
        row.cellConfigAtConfigure.setObject(10, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(0, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: "calculation-device", rowType: XLFormRowDescriptorTypeSelectorPickerViewInline, title: "Calculation Device")
        row.value = Preference.getCalculationDevice()
        options = ["CPU", "GPU", "OpenCV"]
        row.selectorOptions = options
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: "channel", rowType: XLFormRowDescriptorTypeSelectorPickerViewInline, title: "RGB Channel")
        options = ["Red", "Green", "Blue", "Gray"]
        row.value = options[Preference.getChannel()]
        row.selectorOptions = options
        section.addFormRow(row)
        
        let sampleArea = Preference.getSampleArea()
        row = XLFormRowDescriptor(tag: "sample-area-x-0", rowType: XLFormRowDescriptorTypeStepCounter, title: "Sampling X start (%)")
        row.value = sampleArea[0]
        row.cellConfigAtConfigure.setObject(100, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(0, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "sample-area-x-1", rowType: XLFormRowDescriptorTypeStepCounter, title: "Sampling X end (%)")
        row.value = sampleArea[1]
        row.cellConfigAtConfigure.setObject(100, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(0, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "sample-area-y-0", rowType: XLFormRowDescriptorTypeStepCounter, title: "Sampling Y start (%)")
        row.value = sampleArea[2]
        row.cellConfigAtConfigure.setObject(100, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(0, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        row = XLFormRowDescriptor(tag: "sample-area-y-1", rowType: XLFormRowDescriptorTypeStepCounter, title: "Sampling Y end (%)")
        row.value = sampleArea[3]
        row.cellConfigAtConfigure.setObject(100, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(0, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        
        form.addFormSection(section)
        
        // Plot Settings
        section = XLFormSectionDescriptor.formSectionWithTitle("Plot Setting") as XLFormSectionDescriptor
        
        row = XLFormRowDescriptor(tag: "plot-interval", rowType: XLFormRowDescriptorTypeStepCounter, title: "Plot Interval")
        row.value = Preference.getPlotInterval()
        row.cellConfigAtConfigure.setObject(500, forKey: "stepControl.maximumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.minimumValue")
        row.cellConfigAtConfigure.setObject(1, forKey: "stepControl.stepValue")
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: "effective-plot", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: "Effective Plot Mode")
        row.value = Preference.effectivePlotModeOn()
        section.addFormRow(row)
        section.footerTitle = "In \"Effective Plot Mode\", plotting is more likely to be real time, but the shooting might be interrupted sometimes, you will feel laggy when the resolution of photo is high."
        
        form.addFormSection(section)
        
        self.form = form;
    }
    
    @IBAction func saveAndQuit(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func quitWithoutSaving(sender: AnyObject) {
        self.toBeSaved = false
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
