//
//  Shaders.metal
//  Learn-Metal-03
//
//  Created by neotv on 2020/8/27.
//  Copyright © 2020 neotv. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#import "ShaderTypes.h"

typedef struct {
    
    float4 clipSpacePosition [[ position ]];
    
    float4 color;
    
}RasterizerData;


vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant Vertex *vertices [[ buffer(VertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer [[ buffer(VertexInputIndexViewportSize) ]])
{
    // 定义输出 out
    RasterizerData out;
    // 初始化输出剪辑空间位置，将w改为2.0，实际运行结果比1.0小一倍
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    // 获取当前顶点坐标的xy，因为是2D图形
    // 索引到我们的数组位置以获得当前顶点
    // 我们的位置是在像素维度中指定的.
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    // 将vierportSizePointer 从verctor_uint2 转换为vector_float2 类型
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    // 顶点坐标归一化处理
    //每个顶点着色器的输出位置在剪辑空间中(也称为归一化设备坐标空间,NDC),剪辑空间中的(-1,-1)表示视口的左下角,而(1,1)表示视口的右上角.
    //计算和写入 XY值到我们的剪辑空间的位置.为了从像素空间中的位置转换到剪辑空间的位置,我们将像素坐标除以视口的大小的一半.
    //如果是1倍，除以1.0，如果是3倍
    //可以使用一行代码同时分割两个通道。执行除法，然后将结果放入输出位置的x和y通道中
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    // 颜色原样输出
    // 把我们输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.color = vertices[vertexID].color;
    // 将结构体传递到管道中下一个阶段:
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
