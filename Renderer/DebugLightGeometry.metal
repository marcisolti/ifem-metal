//
//  DebugLightGeometry.metal
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
};

// MARK: Vertex shader

vertex RasterizerData
DebugLightVertexShader(uint                      vertexID [[vertex_id]],
                       constant Vertex*          vertices [[buffer(VertexInputIndexVertices)]],
                       constant float4x4* MVP      [[buffer(VertexInputIndexFrameData)]])
{
    RasterizerData out;
    out.position = (*MVP * float4(vertices[vertexID].position, 1.f));
    return out;
}

// MARK: Fragment shader

fragment float4
DebugLightFragmentShader(RasterizerData          in    [[stage_in]],
                         constant float3* color [[buffer(FragmentInputIndexFrameData)]])
{
    return float4(*color, 1.f);
}
