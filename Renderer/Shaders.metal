//
//  Shaders.metal
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#include "ShaderTypes.h"

struct RasterizerData
{
    float4 position [[position]];
    float4 normal;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex* vertices [[buffer(VertexInputIndexVertices)]],
             constant VertexData* vertexData [[buffer(VertexInputIndexFrameData)]])
{
    RasterizerData out;
    out.position = vertexData->MVP * vector_float4(vertices[vertexID].position, 1);
    out.normal = vector_float4(vertices[vertexID].normal, 1);
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant FragmentData* fragmentData [[buffer(FragmentInputIndexFrameData)]])
{
    return in.normal * 0.5 * vector_float4(fragmentData->color, 1.f);
}

