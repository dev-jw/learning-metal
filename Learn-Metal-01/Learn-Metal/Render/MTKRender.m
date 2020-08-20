//
//  MTKRender.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "MTKRender.h"

typedef struct {
    float red;
    float green;
    float blue;
    float alpha;
}Color;


@interface MTKRender ()
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
}
@end

@implementation MTKRender

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        _device = mtkView.device;
        
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

#pragma mark - Private
- (Color)makeFancyColor {
    static BOOL growing = true;
    
    static NSUInteger primaryChannel = 0;
    
    static float colorChannels[] = {1.0, 0.0, 0.0, 1.0};
    
    const float dynamicColorRate = 0.015;
    
    if (growing) {
        NSUInteger dynamicChannelIndex = (primaryChannel + 1) % 3;
        
        colorChannels[dynamicChannelIndex] += dynamicColorRate;
        
        if (colorChannels[dynamicChannelIndex] >= 1.0) {
            growing = false;
            primaryChannel = dynamicChannelIndex;
        }
    }else {
        NSUInteger dynamicChannelIndex = (primaryChannel + 2) % 3;\
        colorChannels[dynamicChannelIndex] -= dynamicColorRate;
        if (colorChannels[dynamicChannelIndex] <= 0.0) {
            growing = true;
        }
    }
    Color color;
    color.red   = colorChannels[0];
    color.green = colorChannels[1];
    color.blue  = colorChannels[2];
    color.alpha = colorChannels[3];
    return color;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    Color color = [self makeFancyColor];
    
    view.clearColor = MTLClearColorMake(color.red, color.green, color.red, color.alpha);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"CommandBuffer";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        renderCommandEncoder.label = @"RenderCommandEncoder";
        
        [renderCommandEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

@end
