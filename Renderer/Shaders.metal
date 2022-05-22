/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

#include "ShaderTypes.h"

struct RasterizerData
{
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant matrix_float4x4 *MVPPointer [[buffer(VertexInputIndexMVP)]])
{
    RasterizerData out;
    out.position = *MVPPointer * vector_float4(vertices[vertexID].position, 1);
    out.color = vector_float4(vertices[vertexID].normal, 1);
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}

