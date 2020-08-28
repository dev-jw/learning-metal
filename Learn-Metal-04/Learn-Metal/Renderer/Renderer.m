//
//  Renderer.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "Renderer.h"

@interface Renderer ()
{
    id<MTLDevice> _device;
    
    id<MTLRenderPipelineState> _renderPipelineState;
    
    id<MTLCommandQueue> _commandQueue;
    
    MTKView *_mtkView;
}
@end

@implementation Renderer

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        _mtkView = mtkView;
        
        _device = mtkView.device;
        
        [self setupPipeline];
        
        [self setupVertex];
        
        [self setupTexture];
    }
    return self;
}

- (void)setupPipeline {
 
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexShader  = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentShader  = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineDes    = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDes.label                           = @"Render Pipeline Descriptor";
    pipelineDes.vertexFunction                  = vertexShader;
    pipelineDes.fragmentFunction                = fragmentShader;
    pipelineDes.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    
    NSError *error;
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDes error:&error];
    NSAssert(_renderPipelineState, @"Failed to created pipeline state, error: %@", error);
    
    _commandQueue = [_device newCommandQueue];
}

- (void)setupVertex {
    
}

- (void)setupTexture {
    
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

@end
