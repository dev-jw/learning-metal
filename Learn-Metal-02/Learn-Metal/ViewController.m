//
//  ViewController.m
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#import "ViewController.h"
#import "MTKRender.h"

@interface ViewController ()
{
    MTKView *_view;
    MTKRender *_render;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _view = (MTKView *)self.view;
    
    _view.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(_view.device, @"Metal is not supported on this device");

    _render = [[MTKRender alloc] initWithMetalKitView:_view];
    
    NSAssert(_render, @"Render failed initalization");
    
    [_render mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _render;
    
}


@end
