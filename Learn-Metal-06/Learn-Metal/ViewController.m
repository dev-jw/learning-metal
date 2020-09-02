//
//  ViewController.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/28.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "ViewController.h"
#import "ShaderTypes.h"
#import "AssetReader.h"

@import MetalKit;
@import GLKit;

@interface ViewController ()<MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) MTKView *mtkView;

@property (nonatomic, strong) AssetReader *assetReader;

/**< 高速纹理读取缓存区 */
@property (nonatomic, assign) CVMetalTextureCacheRef textureCacheRef;
/**< 视口 */
@property (nonatomic, assign) vector_uint2 viewPortSize;

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

/**< 纹理对象 */
@property (nonatomic, strong) id<MTLTexture> texure;
/**< 顶点缓存区 */
@property (nonatomic, strong) id<MTLBuffer> vertices;
/**< 转换矩阵 */
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;

/**< 顶点个数 */
@property (nonatomic, assign) NSInteger numberVertices;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupMTKView];
    
    [self setupAssetReader];
    
    [self setupPipelineState];

    [self setupVertex];

    [self setupMatrix];
}

- (void)setupMTKView {
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    
    self.view = self.mtkView;
    
    self.mtkView.delegate = self;
    
    self.viewPortSize =
    (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
}

- (void)setupAssetReader {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"mp4"];
    
    self.assetReader = [[AssetReader alloc] initWithUrl:url];
    
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCacheRef);
}

- (void)setupPipelineState {
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    id<MTLFunction> vertexShader = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentShader = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor * pipelineDes = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDes.vertexFunction  = vertexShader;
    pipelineDes.fragmentFunction = fragmentShader;
    pipelineDes.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    self.renderPipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineDes error:nil];
    
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

- (void)setupVertex {
    static const Vertex squardVertices[] = {
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    self.vertices = [self.mtkView.device newBufferWithBytes:squardVertices
                                                     length:sizeof(squardVertices)
                                                    options:MTLResourceStorageModeShared];
    
    self.numberVertices = sizeof(squardVertices) / sizeof(Vertex);
}

- (void)setupMatrix {
    // BT.601, which is the standard for SDTV.
    matrix_float3x3 kColorConversion601DefaultMatrix = (matrix_float3x3){
        (simd_float3){1.164,  1.164, 1.164},
        (simd_float3){0.0, -0.392, 2.017},
        (simd_float3){1.596, -0.813,   0.0},
    };
    
    // BT.601 full range
    matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
        (simd_float3){1.0,    1.0,    1.0},
        (simd_float3){0.0,    -0.343, 1.765},
        (simd_float3){1.4,    -0.711, 0.0},
    };
    
    // BT.709, which is the standard for HDTV.
    matrix_float3x3 kColorConversion709DefaultMatrix[] = {
        (simd_float3){1.164,  1.164, 1.164},
        (simd_float3){0.0, -0.213, 2.112},
        (simd_float3){1.793, -0.533,   0.0},
    };
    
    //2.偏移量
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};

    ConvertMatrix matrix;
    
    matrix.matrix = kColorConversion601FullRangeMatrix;
    matrix.offset = kColorConversion601FullRangeOffset;
    
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix
                                                          length:sizeof(ConvertMatrix)
                                                         options:MTLResourceStorageModeShared];
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewPortSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(nonnull MTKView *)view {

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    
    CMSampleBufferRef sampleBuffer = [self.assetReader renderBuffer];
    
    if (renderPassDes && sampleBuffer) {
        renderPassDes.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0);
        
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        
        [encoder setViewport:(MTLViewport){0.0,0.0, self.viewPortSize.x, self.viewPortSize.y , -1.0, 1.0;}];
        
        [encoder setRenderPipelineState:self.renderPipelineState];
        
        [encoder setVertexBuffer:self.vertices offset:0 atIndex:VertexInputIndexVertices];
        
        // 设置纹理
        [self setupTextureWithEncoder:commandEncoder buffer:sampleBuffer];
        
        [encoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:FragmentInputIndexMatrix];
        
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numberVertices];
        
        [encoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder
                         buffer:(CMSampleBufferRef)CMSampleBufferRef
{
    
}

@end
