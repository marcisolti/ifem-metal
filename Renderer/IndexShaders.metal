//
//  IndexShaders.metal
//  iFEM
//
//  Created by Marci Solti on 2022. 06. 06..
//  Copyright © 2022. Apple. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#include "ShaderTypes.h"

struct RasterizerData
{
    float4 position [[position]];
    uint vertexID;
};

vertex RasterizerData
indexVertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant FrameData *frameData [[buffer(VertexInputIndexMVP)]])
{
    RasterizerData out;
    float3 worldPos = (frameData->modelMatrix * float4(vertices[vertexID].position, 1)).xyz;
    out.position = frameData->viewProjMatrix * float4(worldPos, 1);
    out.vertexID = vertexID;
    return out;
}

fragment uint
indexFragmentShader(RasterizerData in [[stage_in]])
{
    return in.vertexID;
}

