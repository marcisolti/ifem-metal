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
    float3 worldPos;
    float3 normal;
    float3 eyePos;
};

// ---------------------------------------------
// *                                           *
// * Shaders                                   *
// *                                           *
// ---------------------------------------------

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant FrameData *frameData [[buffer(VertexInputIndexMVP)]])
{
    RasterizerData out;
    out.worldPos = (frameData->modelMatrix * float4(vertices[vertexID].position, 1)).xyz;
    out.position = frameData->viewProjMatrix * float4(out.worldPos, 1);
    out.normal = (vector_float4(vertices[vertexID].normal, 1) * frameData->modelMatrixInv).xyz;
    out.eyePos = { 0,0,4 };
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}

