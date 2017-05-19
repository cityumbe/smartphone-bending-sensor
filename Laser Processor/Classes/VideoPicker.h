//
//  VideoPicker.h
//  Laser Processor
//
//  Created by Xinhong LIU on 2/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CTAssetsPickerController/CTAssetsPickerController.h>

@interface VideoPicker : NSObject<CTAssetsPickerControllerDelegate>

- (instancetype)init:(UIViewController *)viewController;
- (void)pick:(void (^)(AVAsset *))completion;

@end
