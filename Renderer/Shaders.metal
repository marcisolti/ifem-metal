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
    constexpr float3 lightPos{ 1, 0, 3 };
    constexpr float3 lightColor { 10, 10, 10 };

    const float roughness = pow(1.0-fragmentData->smoothness, 2);
    const float linearRoughness = roughness + 1e-5f;

    float3 N = normalize(in.normal);
    float3 V = normalize(in.eyePos - in.worldPos);

    float NoV = abs(dot(N, V)); // effort to avoid artifact produces artifact

    float3 Lunnormalized = lightPos - in.worldPos;
    float3 L = normalize(Lunnormalized);
    float sqrDist = dot(Lunnormalized, Lunnormalized);
    float illuminance = (1.f / sqrDist);

    float3 H = normalize(V + L);
    float LoH = saturate(dot(L, H));
    float NoH = saturate(dot(N, H));
    float NoL = saturate(dot(N, L));

    // Specular BRDF
    float3 F = F_Schlick(fragmentData->f0, fragmentData->f90, LoH);
    float G = V_SmithGGXCorrelated(NoV, NoL, roughness);
    float D = D_GGX(NoH, roughness);
    float Fr = D * F.x * G / M_PI_F;

    // Diffuse BRDF
    float Fd = Fr_DisneyDiffuse(NoV, NoL, LoH, linearRoughness) / M_PI_F;

    float3 res =
        illuminance *
        NoL *
        (
            (Fd + Fr) * fragmentData->baseColor * lightColor
        );
    return float4(saturate(res), 1);
}

