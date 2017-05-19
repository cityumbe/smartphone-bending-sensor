//
//  DataSetManageTableViewController.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 19/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import PKHUD
import AVKit

class DataSetManageTableViewController: UITableViewController {

    var dataSetManager: DataSetManager!
    var dataSets: [DataSet]?
    
    let dateFormatter = NSDateFormatter()
    
    var emptyLabel: UILabel?
    
    var videoPicker: VideoPicker!
    var videoProcessor: VideoProcessor!
    
    override func viewDidLoad() {
        dataSetManager = DataSetManager()
        self.dataSets = dataSetManager.fetchAllDataSets()
        
        super.viewDidLoad()

        initEmptyLabel()
        initTableViewStyles()
        
        videoPicker = VideoPicker(self as UIViewController)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableViewWithAnimation(true)
    }

    // MARK: - Setups
    
    func initEmptyLabel() {
        self.emptyLabel = UILabel()
        guard let emptyLabel = self.emptyLabel else {
            print("Failed to create emptyLabel")
            exit(-1)
        }
        emptyLabel.text = "Now you do not have any data sets"
        emptyLabel.textColor = UIColor.blackColor()
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .Center
        emptyLabel.font = UIFont(name: "Palatino-Italic", size: 20)
        emptyLabel.sizeToFit()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [NSLayoutConstraint(item: emptyLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: emptyLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1.0, constant: -20.0)]
        self.view.addSubview(emptyLabel)
        self.view.addConstraints(constraints)
    }
    
    func initTableViewStyles() {
        // remove extra rows
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    private func reloadTableViewWithAnimation(reloadDataSet: Bool) {
        if reloadDataSet {
            self.dataSets = dataSetManager.fetchAllDataSets()
        }
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
    }
    
    @IBAction func addDataSet(sender: AnyObject) {
        let optionController = UIAlertController(title: "How?", message: "Choose \"Capture\" will open the camera and capture directly, choose \"Import\" to choose a slo-mo video from your device.", preferredStyle: .ActionSheet)
        optionController.addAction(UIAlertAction(title: "Capture", style: .Default, handler: { (alertAction) -> Void in
            self.performSegueWithIdentifier("capture", sender: self)
        }))
        optionController.addAction(UIAlertAction(title: "Import", style: .Default, handler: { (alertAction) -> Void in
            self.videoPicker.pick({ (videoAsset) -> Void in
                print("self.videoProcessor != nil is \(self.videoProcessor != nil)")
                do {
                    self.videoProcessor = try VideoProcessor(videoAsset: videoAsset)
                } catch let error as NSError {
                    self.showSimpleAlert("Error", message: error.domain, completeHandler: nil)
                    return
                }
                self.videoProcessor.process({ (progress) -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Processing: \(progress)%")
                        PKHUD.sharedHUD.show()
                    })
                    }, completeHandler: { (count) -> Void in
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Totally: \(count) frames")
                            PKHUD.sharedHUD.hide(afterDelay: 0.5)
                            
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
                                    DataSetManager().saveDataSet(alertController.textFields![0].text!, calculationManager: self.videoProcessor.calculationManager)
                                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                        self.videoProcessor = nil
                                        PKHUD.sharedHUD.hide()
                                        self.reloadTableViewWithAnimation(true)
                                        self.dismissViewControllerAnimated(true, completion: nil)
                                        assert(NSThread.isMainThread())
                                    })
                                })
                                
                            }))
                            
                            self.presentViewController(alertController, animated: true, completion: nil)
                            
                        })
                })
            })
        }))
        
        // if it is iPad, use popover
        let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
        if isIPad {
            optionController.modalPresentationStyle = .Popover
            let popoverController = optionController.popoverPresentationController!
            popoverController.barButtonItem = sender as? UIBarButtonItem
        } else {
            // add a cancel button when using iPhone
            // because when popover, tap anywhere else is "cancel"
            optionController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        }
        self.presentViewController(optionController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = self.dataSets!.count
        if numberOfRows > 0 {
            self.emptyLabel?.hidden = true
        } else {
            self.emptyLabel?.hidden = false
        }
        return numberOfRows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dataset_cell", forIndexPath: indexPath)

        cell.textLabel?.text = self.dataSets![indexPath.row].name
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        cell.detailTextLabel?.text = "\(dateFormatter.stringFromDate(self.dataSets![indexPath.row].createdTime)), contains \(self.dataSets![indexPath.row].numberOfImages!) images"

        return cell
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var imageCount = 0
        for dataSet in dataSets! {
            imageCount += dataSet.numberOfImages
        }
        return "in total \(self.dataSets!.count) datasets, \(imageCount) images"
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let dataSetId = dataSets![indexPath.row].id
            dataSetManager.deleteDataSet(dataSetId)
            dataSets?.removeAtIndex(indexPath.row)
            self.reloadTableViewWithAnimation(false)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dataset_detail" {
            let destViewController = segue.destinationViewController as! DataSetViewController
            destViewController.dataSet = self.dataSets![(self.tableView.indexPathForSelectedRow!.row)]
        }
    }
}
