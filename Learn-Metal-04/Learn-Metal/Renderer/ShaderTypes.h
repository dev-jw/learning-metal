//
//  ShaderTypes.h
//  Learn-Metal
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

typedef enum VertexInputIndex {
    VertexInputIndexVertices = 0,
    VertexInputIndexViewportSize = 1
}VertexInputIndex;

typedef enum TextureIndex {
    TextureIndexBaseColor = 0
}TextureIndex;

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
}Vertex;

#endif /* ShaderTypes_h */
