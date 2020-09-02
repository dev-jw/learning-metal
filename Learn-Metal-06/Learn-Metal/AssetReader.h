//
//  AssetReader.h
//  Learn-Metal
//
//  Created by neotv on 2020/9/2.
//  Copyright © 2020 neotv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetReader : NSObject

- (instancetype)initWithUrl:(NSURL *)url;

- (CMSampleBufferRef)renderBuffer;

@end

NS_ASSUME_NONNULL_END
