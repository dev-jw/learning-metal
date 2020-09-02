//
//  ShaderTypes.h
//  Learn-Metal
//
//  Created by neotv on 2020/9/2.
//  Copyright © 2020 neotv. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
    // 顶点坐标
    vector_float4 position;
    // 纹理坐标
    vector_float2 textureCoordinate;
}Vertex;

typedef struct {
    // 转换矩阵
    matrix_float3x3 matrix;
    
    // 偏移值
    vector_float3 offset;
}ConvertMatrix;

// 顶点函数缓冲区索引
typedef enum VertexInputIndex {
    VertexInputIndexVertices = 0,
}VertexInputIndex;

//片元函数转换矩阵缓存区索引
typedef enum FragmentBufferIndex {
    FragmentInputIndexMatrix = 0,
}FragmentBufferIndex;

// 片段函数纹理索引
typedef enum FragmentTextureIndex {
    // Y
    FragmentTextureIndexTextureY = 0,
    // UV
    FragmentTextureIndexTextureUV = 1,
}FragmentTextureIndex;

#endif /* ShaderTypes_h */
