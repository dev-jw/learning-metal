//
//  ViewController.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/28.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "ViewController.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@import GLKit;
@import MetalKit;
@import AVFoundation;
@import CoreVideo;

@interface ViewController ()<MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

/**< MTKView */
@property (nonatomic, strong) MTKView *mtkView;

/**< 负责输入和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession *session;

/**< 输入设备 */
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;

/**< 输出设备 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *deviceOutput;

/**< 采集队列 */
@property (nonatomic, strong) dispatch_queue_t processQueue;

/**< 纹理缓冲区 */
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

/**< 命令队列 */
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

/**< 纹理对象 */
@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置 Metal
    [self setupMetal];
    
    // 设置 AVFoundation 视频采集
    [self setupCaptureSession];
}

- (void)setupMetal {
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    [self.view insertSubview:self.mtkView atIndex:0];

    self.mtkView.delegate = self;
    
    // 设置MTKView的dramwable纹理是可读写的；（默认是只读）
    self.mtkView.framebufferOnly = false;
    
    self.commandQueue = [self.mtkView.device newCommandQueue];

    /*
     CVMetalTextureCacheCreate(CFAllocatorRef  allocator,
     CFDictionaryRef cacheAttributes,
     id <MTLDevice>  metalDevice,
     CFDictionaryRef  textureAttributes,
     CVMetalTextureCacheRef * CV_NONNULL cacheOut )
     
     功能: 创建纹理缓存区
     参数1: allocator 内存分配器.默认即可.NULL
     参数2: cacheAttributes 缓存区行为字典.默认为NULL
     参数3: metalDevice
     参数4: textureAttributes 缓存创建纹理选项的字典. 使用默认选项NULL
     参数5: cacheOut 返回时，包含新创建的纹理缓存。
     */
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

- (void)setupCaptureSession {
    self.session = [[AVCaptureSession alloc] init];
    
    self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
    
    self.processQueue = dispatch_queue_create("captureProcess", DISPATCH_QUEUE_SERIAL);
    
    NSArray *devices;
    if (@available(iOS 10.0, *)) {

        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        devices = devicesIOS10.devices;
    }else {
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }

    AVCaptureDevice *inputCamera = nil;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            inputCamera = device;
        }
    }
    
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    
    self.deviceOutput = [[AVCaptureVideoDataOutput alloc] init];
        /**< 视频帧延迟是否需要丢帧 */
    self.deviceOutput.alwaysDiscardsLateVideoFrames = false;
    self.deviceOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.deviceOutput setSampleBufferDelegate:self queue:self.processQueue];
    
    if ([self.session canAddOutput:self.deviceOutput]) {
        [self.session addOutput:self.deviceOutput];
    }
    
    AVCaptureConnection *connection = [self.deviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [self.session startRunning];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(nonnull MTKView *)view {
    if (self.texture) {
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        id<MTLTexture> drawingTexture = view.currentDrawable.texture;
        
        MPSImageGaussianBlur *filter =
        [[MPSImageGaussianBlur alloc] initWithDevice:self.mtkView.device sigma:1];
        
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
        
        [commandBuffer presentDrawable:view.currentDrawable];
        
        [commandBuffer commit];
        
        self.texture = nil;
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    size_t width  = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn res = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatRGBA8Unorm, width, height, 0, &tmpTexture);
    
    if (res == kCVReturnSuccess) {
        self.mtkView.drawableSize = CGSizeMake(width, height);
        
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        
        CFRelease(tmpTexture);
    }
}
@end
