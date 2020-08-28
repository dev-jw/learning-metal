//
//  Renderer.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "Renderer.h"
#include "ShaderTypes.h"

@interface Renderer ()
{
    id<MTLDevice> _device;
    
    id<MTLRenderPipelineState> _renderPipelineState;
    
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLBuffer> _vertexBuffer;
    
    NSInteger _numberVertices;
    
    id<MTLTexture> _texture;
    
    vector_int2 _viewportSize;
    
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
    static const Vertex squardVertices[] = {
        { {  250, -250 }, { 1.0f, 0.0f } },
        { { -250, -250 }, { 0.0f, 0.0f } },
        { { -250,  250 }, { 0.0f, 1.0f } },
        
        { {  250, -250 }, { 1.0f, 0.0f } },
        { { -250,  250 }, { 0.0f, 1.0f } },
        { {  250,  250 }, { 1.0f, 1.0f } },
    };
    _vertexBuffer = [_device newBufferWithBytes:squardVertices length:sizeof(squardVertices) options:MTLResourceStorageModeShared];
    
    _numberVertices = sizeof(squardVertices) / sizeof(Vertex);
}

- (void)setupTexture {
    UIImage *image = [UIImage imageNamed:@"wlop.png"];
    
    MTLTextureDescriptor *textureDes = [[MTLTextureDescriptor alloc] init];
    textureDes.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDes.width    = image.size.width;
    textureDes.height   = image.size.height;
    
    _texture = [_device newTextureWithDescriptor:textureDes];
   
    MTLRegion region = {
        {0, 0, 0},
        {image.size.width, image.size.height, 1},
    };
    
    Byte *imageBytes = [self loadImage:image];
    NSAssert(imageBytes, @"imageBytes load failed");

    [_texture replaceRegion:region
                mipmapLevel:0
                  withBytes:imageBytes
                bytesPerRow:4 * image.size.width];
    
    free(imageBytes);
    imageBytes = NULL;
}

- (Byte *)loadImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    NSAssert(imageRef, @"Image load failed");
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    Byte *spriteData = (Byte*)calloc(width * height * 4, sizeof(Byte));
    
    CGContextRef contextRef = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(contextRef, rect, imageRef);
    CGContextTranslateCTM(contextRef, 0, rect.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    CGContextDrawImage(contextRef, rect, imageRef);

    CGContextRelease(contextRef);
    CGImageRelease(imageRef);
    
    return spriteData;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Sample Texture";
    
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    if (renderPassDes != nil) {
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        commandEncoder.label = @"Command Encoder";
        
        [commandEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        
        [commandEncoder setRenderPipelineState:_renderPipelineState];
        
        [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
        
        [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
        
        [commandEncoder setFragmentTexture:_texture atIndex:TextureIndexBaseColor];
        
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numberVertices];
        
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}
@end
