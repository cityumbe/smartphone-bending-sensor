//
//  DataSetViewController.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 20/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import SSZipArchive
import PKHUD

class DataSetViewController: UIViewController, UITableViewDataSource {

    var dataSet: DataSet!
    
    var baseImages: [DataSetImage]!
    var dataSetImages: [DataSetImage]!
    
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var dataSetName: UILabel!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var baseImageTimeLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        let dataSetManager = DataSetManager()
        
        let result = dataSetManager.fetchAllImages(dataSet.id)
        self.baseImages = result.baseImages
        self.dataSetImages = result.images
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.baseImageTimeLabel.text = dateFormatter.stringFromDate(self.baseImages[0].createdTime)
        self.dataSetName.text = self.dataSet.name
        self.imageCountLabel.text = "\(dataSet.numberOfImages) images"
        
        // baseImage
        let baseImageFilePath = "\(DataSetManager.imagesDirPath())/\(self.dataSet.id)/\(self.baseImages[0].id).png"
        self.baseImageView.image = UIImage(contentsOfFile: baseImageFilePath)
        
        super.viewDidLoad()
    }

    func configureBaseImage() {
        dataSetName.text = dataSet.name
        imageCountLabel.text = "\(dataSet.numberOfImages) images"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSetImages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("dataset_image_cell") as? DataSetImageTableViewCell
        
        let dataSetImage = dataSetImages[indexPath.row]
        
        cell?.correlationLabel.text = "Correlation: \(String(format: "%.6lf", arguments: [dataSetImage.correlation!]))"
        let deltaSec = dataSetImage.createdTime.timeIntervalSinceDate(baseImages[0].createdTime)
        cell?.timeLabel.text = "\(dataSetImage.id)(\(indexPath.row + 1)): \(String(format: "%.3lf", arguments: [deltaSec])) sec(s) later"
        let imageFilePath = "\(DataSetManager.imagesDirPath())/\(self.dataSet.id)/\(dataSetImage.id).png"
        cell?.dataSetImageView.image = UIImage(contentsOfFile: imageFilePath)
        
        return cell!
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: Share
    func shareData(sender: AnyObject) {
        let datPath = "\(DataSetManager.cacheDirPath())/\(dataSet.name).dat"
        PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Preparing...")
        PKHUD.sharedHUD.show()
        
        NSOperationQueue().addOperationWithBlock {
            var string = ""
            for i in 1...(self.dataSetImages.count-1) {
                let dataSetImage = self.dataSetImages[i]
                string.appendContentsOf("\(dataSetImage.correlation!)\n")
            }
            do {
                try string.writeToFile(datPath, atomically: true, encoding: NSUTF8StringEncoding)
                NSOperationQueue.mainQueue().addOperationWithBlock({
                PKHUD.sharedHUD.hide(animated: true)
                let activityViewController = UIActivityViewController(activityItems: [NSURL.fileURLWithPath(datPath)], applicationActivities: nil)
                self.presentViewController(activityViewController, animated: true, completion: nil)
                })
            } catch {
                print("\(error)")
            }
        }
    }
    
    func shareZip(sender: AnyObject) {
        let zipPath = "\(DataSetManager.cacheDirPath())/\(dataSet.name).zip"
        PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Archiving...")
        PKHUD.sharedHUD.show()
        
        NSOperationQueue().addOperationWithBlock {
            SSZipArchive.createZipFileAtPath(zipPath, withContentsOfDirectory: "\(DataSetManager.imagesDirPath())/\(self.dataSet.id)")
            NSOperationQueue.mainQueue().addOperationWithBlock({
                PKHUD.sharedHUD.hide(animated: true)
                let activityViewController = UIActivityViewController(activityItems: [NSURL.fileURLWithPath(zipPath)], applicationActivities: nil)
                self.presentViewController(activityViewController, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func share(sender: AnyObject) {
        let alertController = UIAlertController(title: "Share", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Images", style: .Default, handler: { (_) in
            self.shareZip(sender)
        }))
        alertController.addAction(UIAlertAction(title: "Data", style: .Default, handler: { (_) in
            self.shareData(sender)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
