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
// * BRDF                                      *
// *                                           *
// ---------------------------------------------

float3 F_Schlick(float3 f0, float f90, float u)
{
    return f0 + (f90 - f0) * pow(1.f - u, 5.f);
}

float Fr_DisneyDiffuse(float NdotV, float NdotL, float LdotH, float linearRoughness)
{
    float fd90 = 0.5 - 2.0 * LdotH * LdotH * linearRoughness;
    float3 f0 = float3(1.0f, 1.0f, 1.0f);
    float lightScatter = F_Schlick(f0, fd90, NdotL).r;
    float viewScatter = F_Schlick(f0, fd90, NdotV).r;

    return lightScatter * viewScatter;
}

float V_SmithGGXCorrelated(float NdotL, float NdotV, float alphaG)
{
    float alphaG2 = alphaG * alphaG;

    float Lambda_GGXV = NdotL * sqrt((-NdotV * alphaG2 + NdotV) * NdotV + alphaG2);
    float Lambda_GGXL = NdotV * sqrt((-NdotL * alphaG2 + NdotL) * NdotL + alphaG2);

    return 0.5f / (Lambda_GGXV + Lambda_GGXL);
}

float D_GGX(float NdotH, float m)
{
    float m2 = m * m;
    float f = (NdotH * m2 - NdotH) * NdotH + 1;

    return m2 / (f * f);
}

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
    float3 baseColorMap = {1,0.3,1};
    float shinyMap = 0.6;

    float metalness = 1.f;

    float roughness = pow(1.0-shinyMap, 2);
    float linearRoughness = roughness + 1e-5f;
    float f0 = 0.3f;
    float f90 = 1.f;

    float3 N = normalize(in.normal);
    float3 V = normalize(in.eyePos - in.worldPos);

    float NdotV = abs(dot(N, V)) + 1e-5f; // avoid artifact (?)

    float3 lightPos = { 0, 0, 3 };
    float3 Lunnormalized = lightPos - in.worldPos;
    float3 L = normalize(Lunnormalized);
    float sqrDist = dot(Lunnormalized, Lunnormalized);
    float illuminance = 8.f * (1.f / sqrDist);

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
            (Fd + Fr) * baseColorMap * float3(1,1,1)
        );
    return float4(res, 1);
}

