//
//  MTKShaders.metal
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#include <metal_stdlib>
#include "MTKShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 position [[position]];
    
    float4 color;
} RasterizerData;

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant vector_float2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
    RasterizerData out;
    
    out.position = vertices[vertexID].position;
    out.color  = vertices[vertexID].color;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
