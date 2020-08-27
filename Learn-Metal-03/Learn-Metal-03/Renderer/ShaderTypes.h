//
//  ShaderTypes.h
//  Learn-Metal-03
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用，相当于OpenGL ES中GLSL文件中position参数名称，即入口
//数据传递时的房间号，metal中表示index，类似于GLSL中的getAttribLocation、getUniformLocation
typedef enum VertexInputIndex
{
//    顶点
    VertexInputIndexVertices = 0,
    
//    视图大小
    VertexInputIndexViewportSize = 1,
    
}VertexInputIndex;


//顶点数据结构体:顶点/颜色值
typedef struct
{
//    像素空间的位置
//    像素中心点（100，100）
    vector_float2 position;
    
//    RGBA颜色
    vector_float4 color;
}Vertex;

#endif /* ShaderTypes_h */
