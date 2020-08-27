//
//  Renderer.m
//  Learn-Metal-03
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "Renderer.h"
#import "ShaderTypes.h"

@interface Renderer ()
{
    id<MTLDevice> _device;
    
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLRenderPipelineState> _pipelineState;
    
    id<MTLBuffer> _vertexBuffer;
    
    vector_uint2 _viewportSize;
    
    NSInteger _numberVertex;
}
@end

@implementation Renderer

// 顶点数据 -- 制造出非常多的顶点数据
+ (nonnull NSData*)generateVertexData {
//  正方形 = 三角形+三角形
    const Vertex quadVertices[] =
    {
//        顶点坐标位于物体坐标系，需要在顶点着色函数中作归一化处理，即物体坐标系 -- NDC
        // Pixel 位置, RGBA 颜色
        { { -20,   20 },    { 1, 0, 0, 1 } },
        { {  20,   20 },    { 1, 0, 0, 1 } },
        { { -20,  -20 },    { 1, 0, 0, 1 } },
        
        { {  20,  -20 },    { 0, 0, 1, 1 } },
        { { -20,  -20 },    { 0, 0, 1, 1 } },
        { {  20,   20 },    { 0, 0, 1, 1 } },
    };
    
    //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(Vertex);
    //四边形间距
    const float QUAD_SPACING = 50.0;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSInteger dataStr = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
//  开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataStr];
    //当前四边形
    Vertex *currentQuad = vertexData.mutableBytes;
    
//    3、获取顶点坐标（循环计算）??? 需要研究
    //行
    for (NSUInteger row = 0; row < NUM_ROWS; row++) {
        //列
        for (NSUInteger column = 0; column < NUM_COLUMNS; column++) {
            //A.左上角的位置
            vector_float2 upperLeftPosition;
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++) {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            //E.更新索引
            currentQuad += 6;
        }
    }
    return vertexData;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView {
    self = [super init];
    if (self) {
        _device = mtkView.device;
        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

        id<MTLLibrary> defaultLibrary  = [_device newDefaultLibrary];
        id<MTLFunction> vertexShader   = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentShader = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        MTLRenderPipelineDescriptor *pipelineDes    = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDes.vertexFunction                  = vertexShader;
        pipelineDes.fragmentFunction                = fragmentShader;
        pipelineDes.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        NSError *error;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDes error:&error];
        NSAssert(_pipelineState, @"Failed to created pipeline state, error %@", error);
        
        NSData *vertexData = [Renderer generateVertexData];
        
        _vertexBuffer = [_device newBufferWithBytes:vertexData.bytes length:vertexData.length options:MTLResourceStorageModeShared];
        
        memcmp(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
        
        _numberVertex = vertexData.length / sizeof(Vertex);
        
        _commandQueue = [_device newCommandQueue];
        
    }
    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}


- (void)drawInMTKView:(nonnull MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Simple Command Buffer";
   
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    
    if (renderPassDes) {
        id<MTLRenderCommandEncoder> commandEncoer = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        commandEncoer.label = @"Simple Command Encoer";
        
        [commandEncoer setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        
        [commandEncoer setRenderPipelineState:_pipelineState];
        
        [commandEncoer setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
        
        [commandEncoer setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
        
        [commandEncoer drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numberVertex];
        
        [commandEncoer endEncoding];
    
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

@end
