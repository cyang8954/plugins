//
//  FLTPHPickerImageHandlingOperation.m
//  image_picker
//
//  Created by Chris Yang on 6/15/21.
//

#import "FLTPHPickerImageHandlingOperation.h"
#import <PhotosUI/PhotosUI.h>
#import "FLTImagePickerImageUtil.h"
#import "FLTImagePickerMetaDataUtil.h"
#import "FLTImagePickerPhotoAssetUtil.h"

@interface FLTPHPickerImageHandlingOperation()

@property (strong, nonatomic) PHPickerResult* result;
@property (weak, nonatomic) NSMutableArray *pathList;
@property (assign, nonatomic) NSNumber* maxHeight;
@property (assign, nonatomic) NSNumber* maxWidth;
@property (assign, nonatomic) NSNumber* desiredImageQuality;
@property (assign, nonatomic) NSInteger index;

@end

@implementation FLTPHPickerImageHandlingOperation

- (void)start {
  [self setValue:@(YES) forKeyPath:@"executing"];
  [self.result.itemProvider
      loadObjectOfClass:[UIImage class]
      completionHandler:^(__kindof id<NSItemProviderReading> _Nullable image,
                          NSError *_Nullable error) {
        if ([image isKindOfClass:[UIImage class]]) {
          __block UIImage *localImage = image;
          PHAsset *originalAsset =
              [FLTImagePickerPhotoAssetUtil getAssetFromPHPickerResult:self.result];

          if (self.maxWidth != (id)[NSNull null] || self.maxHeight != (id)[NSNull null]) {
            localImage = [FLTImagePickerImageUtil scaledImage:localImage
                                                     maxWidth:self.maxWidth
                                                    maxHeight:self.maxHeight
                                          isMetadataAvailable:originalAsset != nil];
          }
          __block NSString *savedPath;
          if (!originalAsset) {
            // Image picked without an original asset (e.g. User pick image without permission)
            savedPath =
                [FLTImagePickerPhotoAssetUtil saveImageWithPickerInfo:nil
                                                                image:localImage
                                                         imageQuality:self.desiredImageQuality];
            self.pathList[self.index] = savedPath;

          } else {
            [[PHImageManager defaultManager]
                requestImageDataForAsset:originalAsset
                                 options:nil
                           resultHandler:^(
                               NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                               UIImageOrientation orientation, NSDictionary *_Nullable info) {
                             // maxWidth and maxHeight are used only for GIF images.
                             savedPath = [FLTImagePickerPhotoAssetUtil
                                 saveImageWithOriginalImageData:imageData
                                                          image:localImage
                                                       maxWidth:self.maxWidth
                                                      maxHeight:self.maxHeight
                                                   imageQuality:self.desiredImageQuality];
              self.pathList[self.index] = savedPath;
                           }];
          }
        }
        [self setValue:@(NO) forKeyPath:@"executing"];
        [self setValue:@(YES) forKeyPath: @"finished"];
      }];
}

@end
