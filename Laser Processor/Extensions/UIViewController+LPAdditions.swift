//
//  UIViewController+LPAdditions.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 6/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit

extension UIViewController {
    func showSimpleAlert(title: String, message: String, completeHandler: (()->Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (_) -> Void in
            completeHandler?()
        }))
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}
