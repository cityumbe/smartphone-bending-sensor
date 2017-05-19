//
//  VideoPicker.m
//  Laser Processor
//
//  Created by Xinhong LIU on 2/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

#import "VideoPicker.h"

@implementation VideoPicker {
    __weak UIViewController *_viewController;
    void (^_completion)(AVAsset *);
}

- (instancetype)init:(UIViewController *)viewController {
    self = [super init];
    
    if (self != nil) {
        _viewController = viewController;
    }
    
    return self;
}

- (void)pick:(void (^)(AVAsset *))completion {
    
    _completion = completion;
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        
        // init picker
        CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
        
        // set delegate
        picker.delegate = self;
        
        // create options for fetching slo-mo videos only
        PHFetchOptions *assetsFetchOptions = [PHFetchOptions new];
        assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %i", PHAssetMediaTypeVideo];
        
        // assign options
        picker.assetsFetchOptions = assetsFetchOptions;
        
        // hide empty albums
        picker.showsEmptyAlbums = NO;
        
        // Optionally present picker as a form sheet on iPad
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            picker.modalPresentationStyle = UIModalPresentationFormSheet;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_viewController presentViewController:picker animated:YES completion:nil];
        });
    }];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(PHAsset *)asset {
    return picker.selectedAssets.count == 0;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    NSLog(@"selected");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [picker dismissViewControllerAnimated:YES completion:nil];
    }];
    
    PHAsset *phAsset = assets[0];
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        _completion(asset);
    }];
}

@end
