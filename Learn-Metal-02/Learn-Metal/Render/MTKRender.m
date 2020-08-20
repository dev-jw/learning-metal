//
//  MTKRender.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "MTKRender.h"
#import "MTKShaderTypes.h"

@interface MTKRender ()
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    
    vector_uint2 _viewportSize;
}
@end

@implementation MTKRender

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        _device = mtkView.device;
        
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
        id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexShader"];
        
        id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.label = @"pipelineDescriptor";
        pipelineDescriptor.vertexFunction = vertexFunc;
        pipelineDescriptor.fragmentFunction = fragmentFunc;
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        
        NSAssert(_pipelineState, @"Failed to created pipeline state, error:%@", error);
        
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(MTKView *)view {
        
    static const Vertex triangleVertices[] = {
        {{0.5, -0.25, 0.0, 1.0}, {1, 0, 0, 1}},
        {{-0.5, -0.25, 0.0, 1.0}, {0, 1, 0, 1}},
        {{-0.0, 0.25, 0.0, 1.0}, {0, 0, 1, 1}},
    };
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"CommandBuffer";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderCommandEncoder.label = @"RenderCommandEncoder";
        
        MTLViewport viewportSize = {
            0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0
        };
        
        [renderCommandEncoder setViewport:viewportSize];
        
        [renderCommandEncoder setRenderPipelineState:_pipelineState];
        
        [renderCommandEncoder setVertexBytes:triangleVertices
                                      length:sizeof(triangleVertices)
                                     atIndex:VertexInputIndexVertices];
        [renderCommandEncoder setVertexBytes:&_viewportSize
                                      length:sizeof(_viewportSize)
                                     atIndex:VertexInputIndexViewportSize];
        
        
        [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        
        [renderCommandEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

@end
