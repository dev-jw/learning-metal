//
//  AssetReader.m
//  Learn-Metal
//
//  Created by neotv on 2020/9/2.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "AssetReader.h"

@implementation AssetReader
{
    AVAssetReader *assetReader; /**< 从原始数据里获取解码后的音视频数据 */
    AVAssetReaderTrackOutput *readerVideoTrackOutput; /**< 轨道 */
    
    NSURL *videoUrl;
    NSLock *lock;
}

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    
    lock = [[NSLock alloc] init];
    videoUrl = url;
    
    [self setupAssetReader];
    
    return self;
}

- (void)setupAssetReader {
    /**< AVURLAssetPreferPreciseDurationAndTimingKey 默认为NO,YES表示提供精确的时长 */
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:@(true) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    /**< 创建 AVURLAsset，是 AVAsset 的子类，用于从本地/远程 URL 初始化数据 */
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:inputOptions];
    
    /**< 异步加载资源 */
    
    /**< 弱引用，解决循环引用 */
    __weak typeof(self) weakSelf = self;
    
    /**< 定义属性名称 */
    NSString *tracks = @"tracks";
    
    /**< 对资源所需的键执行标准的异步载入操作，这样就可以在访问资源的 tracks 属性时，不受到阻碍 */
    [inputAsset loadValuesAsynchronouslyForKeys:@[tracks] completionHandler:^{
        
        /**< 延长self 生命周期 */
        __strong typeof(self) strongSelf = weakSelf;
        
        /**< 开辟子线程，并发队列-异步函数， 来处理读取 inputAsset */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            
            /**< 获取状态码 */
            AVKeyValueStatus trackStatus = [inputAsset statusOfValueForKey:tracks error:&error];
            
            /**< 如果状态不等于成功加载，返回并打印错误 */
            if (trackStatus != AVKeyValueStatusLoaded) {
                NSLog(@"asset load failed, error: %@", error);
                return;
            }
            
            /**< 处理读取的 inputAsset */
            [weakSelf processWithAsset:inputAsset];
        });
    }];
    
}

- (void)processWithAsset:(AVAsset *)asset {
    [lock lock];
    
    NSError *error = nil;
    
    /**< 创建 AVAssetReader */
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    /*
     在iOS中，当前仅支持的键是AVVideoCodecKey和kCVPixelBufferPixelFormatTypeKey。
     并且，键是互斥的-只能存在一个。
     推荐值为
     AVVideoCodecKey - kCMVideoCodecType_JPEG
     kCVPixelBufferPixelFormatTypeKey - kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
     kCVPixelFormatType_32BGRA - kCVPixelBufferPixelFormatTypeKey.。
     */
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    /*
     assetReaderTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(nullable NSDictionary<NSString *, id> *)outputSettings
     参数1: 表示读取资源中的信息
     参数2: 视频输出参数
     */
    readerVideoTrackOutput =
    [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:
     [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                               outputSettings:outputSettings];
    /**< 表示缓存区的数据输出之前是否会被复制
     YES:输出总是从缓存区提供复制的数据,你可以自由的修改这些缓存区数据 */
    readerVideoTrackOutput.alwaysCopiesSampleData = false;
    
    /**< 为assetReader 填充输出 */
    [assetReader addOutput:readerVideoTrackOutput];
    
    /**< assetReader 开始读取.并且判断是否开始 */
    if ([assetReader startReading] == false) {
        NSLog(@"Error reading from file at URL: %@", asset);
    }
    
    [lock unlock];
}

- (CMSampleBufferRef)renderBuffer {
    /**< 加锁 */
    [lock lock];
    CMSampleBufferRef sampleBufferRef = nil;
    
    /**< 判断readerVideoTrackOutput 是否创建成功 */
    if (readerVideoTrackOutput) {
         /**< 复制下一个缓存区的内容到sampleBufferRef */
        sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
    }
    
     /**
      判断assetReader存在 并且status是已经完成读取
      则重新清空readerVideoTrackOutput和assetReader
      并重新初始化它们
      */
    if (assetReader && assetReader.status == AVAssetReaderStatusCompleted) {
        NSLog(@"customInit");
        readerVideoTrackOutput = nil;
        assetReader = nil;
        [self setupAssetReader];
    }
    
     /**< 解锁 */
    [lock unlock];
    
    return sampleBufferRef;
}

@end
