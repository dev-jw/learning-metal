//
//  Shaders.metal
//  Learn-Metal
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

typedef struct {
    float4 clipSpacePosition [[ position ]];
    float2 textureCoordinate;
}RasterizerData;

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertexArray [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
    RasterizerData out;
    
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    out.clipSpacePosition.z = 0.0;
    
    out.clipSpacePosition.w = 1.0;
    
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    
    return out;
}

fragment float4
fragmentShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[texture(TextureIndexBaseColor)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    const half4 colorSampler = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    return float4(colorSampler);
}
