//
//  Shaders.metal
//  Learn-Metal
//
//  Created by neotv on 2020/9/2.
//  Copyright © 2020 neotv. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

typedef struct {
    float4 clipSpacePosition [[position]];
    
    float2 textureCoordinate;
} RasterizerData;

vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant Vertex *vertexArray [[buffer(VertexInputIndexVertices)]])
{
    RasterizerData out;
    
    out.clipSpacePosition = vertexArray[vertexID].position;
    
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    
    return out;
}


fragment float4
fragmentShader(RasterizerData in [[stage_in]],
               texture2d<float> textureY [[texture(FragmentTextureIndexTextureY)]],
               texture2d<float> textureUV [[texture(FragmentTextureIndexTextureUV)]],
               constant ConvertMatrix *convertMatrix [[buffer(FragmentInputIndexMatrix)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);

    /*
     读取YUV 纹理对应的像素点值，即颜色值
     textureY.sample(textureSampler, input.textureCoordinate).r
     从textureY中的纹理采集器中读取,纹理坐标对应上的R值.(Y)
     textureUV.sample(textureSampler, input.textureCoordinate).rg
     从textureUV中的纹理采集器中读取,纹理坐标对应上的RG值.(UV)
     */
    //r 表示 第一个分量，相当于 index 0
    //rg 表示 数组中前面两个值，相当于 index 的0 和 1，用xy也可以
    float3 yuv = float3(textureY.sample(textureSampler, in.textureCoordinate).r,
                        textureUV.sample(textureSampler, in.textureCoordinate).rg);
    
    // 将YUV 转化为 RGB值.convertMatrix->matrix * (YUV + convertMatrix->offset)
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    return float4(rgb, 1.0);
}
