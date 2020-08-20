//
//  MTKRender.h
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface MTKRender : NSObject<MTKViewDelegate>

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
