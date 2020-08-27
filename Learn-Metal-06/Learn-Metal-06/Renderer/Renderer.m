//
//  Renderer.m
//  Learn-Metal-03
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "Renderer.h"

@interface Renderer ()
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
}
@end

@implementation Renderer

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        _device = mtkView.device;
        
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

@end
