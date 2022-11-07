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
#include "BRDF.h"

struct RasterizerData
{
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float3 eyePos;
};

// MARK: Vertex shader

vertex RasterizerData
vertexShader(uint                 vertexID   [[vertex_id]],
             constant Vertex*     vertices   [[buffer(VertexInputIndexVertices)]],
             constant VertexData* vertexData [[buffer(VertexInputIndexFrameData)]])
{
    RasterizerData out;
    out.worldPos = (vertexData->modelMatrix * float4(vertices[vertexID].position, 1)).xyz;
    out.position = vertexData->viewProjMatrix * float4(out.worldPos, 1);
    out.normal = (vector_float4(vertices[vertexID].normal, 1) * vertexData->modelMatrixInv).xyz;
    out.eyePos = vertexData->eyePos;
    return out;
}

// MARK: Fragment shader

fragment float4
fragmentShader(RasterizerData         in           [[stage_in]],
               constant FragmentData* fragmentData [[buffer(FragmentInputIndexFrameData)]])
{
    constexpr float3 lightPos{ -1, 0, 3 };
    constexpr float3 lightColor { 10, 10, 10 };

    float3 baseColorMap = fragmentData->color;
    float shinyMap = 0.6;

    float roughness = pow(1.0-shinyMap, 2);
    float linearRoughness = roughness + 1e-5f;
    float f0 = 0.3f;
    float f90 = 1.f;

    float3 N = normalize(in.normal);
    float3 V = normalize(in.eyePos - in.worldPos);

    float NdotV = abs(dot(N, V)); // effort to avoid artifact produces artifact

    float3 Lunnormalized = lightPos - in.worldPos;
    float3 L = normalize(Lunnormalized);
    float sqrDist = dot(Lunnormalized, Lunnormalized);
    float illuminance = (1.f / sqrDist);

    float3 H = normalize(V + L);
    float LdotH = saturate(dot(L, H));
    float NdotH = saturate(dot(N, H));
    float NdotL = saturate(dot(N, L));

    // Specular BRDF
    float3 F = F_Schlick(f0, f90, LdotH);
    float Vis = V_SmithGGXCorrelated(NdotV, NdotL, roughness);
    float D = D_GGX(NdotH, roughness);
    float Fr = D * F.x * Vis / M_PI_F;

    // Diffuse BRDF
    float Fd = Fr_DisneyDiffuse(NdotV, NdotL, LdotH, linearRoughness) / M_PI_F;

    float3 res =
        illuminance *
        NdotL *
        (
            (Fd + Fr) * baseColorMap * lightColor
        );
    return float4(saturate(res), 1);
}

