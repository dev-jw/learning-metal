//
//  MTKShaderTypes.h
//  Learn-Metal
//
//  Created by neotv on 2020/8/20.
//  Copyright © 2020 neotv. All rights reserved.
//

#ifndef MTKShaderTypes_h
#define MTKShaderTypes_h

#include <simd/simd.h>

typedef enum VertexInputIndex
{
    VertexInputIndexVertices = 0,
    VertexInputIndexViewportSize = 1
} VertexInputIndex;

typedef struct
{
    vector_float4 position;
    vector_float4 color;
} Vertex;

#endif /* MTKShaderTypes_h */
