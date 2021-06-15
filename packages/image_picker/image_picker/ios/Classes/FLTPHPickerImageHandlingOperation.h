//
//  FLTPHPickerImageHandlingOperation.h
//  image_picker
//
//  Created by Chris Yang on 6/15/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTPHPickerImageHandlingOperation : NSOperation

// Needs to be called after the operation is finished.
- (NSString *)getPathString;

@end

NS_ASSUME_NONNULL_END
