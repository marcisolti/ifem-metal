//
//  BRDF.h
//  iFEM
//
//  Created by Marci Solti on 2022. 11. 06..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <metal_stdlib>

float3 F_Schlick(float3 f0, float f90, float u)
{
    return f0 + (f90 - f0) * pow(1.f - u, 5.f);
}

float Fr_DisneyDiffuse(float NdotV, float NdotL, float LdotH, float linearRoughness)
{
    const float fd90 = 0.5 - 2.0 * LdotH * LdotH * linearRoughness;
    const float3 f0 = float3(1.0f, 1.0f, 1.0f);
    const float lightScatter = F_Schlick(f0, fd90, NdotL).r;
    const float viewScatter = F_Schlick(f0, fd90, NdotV).r;

    return lightScatter * viewScatter;
}

float V_SmithGGXCorrelated(float NdotL, float NdotV, float alphaG)
{
    const float alphaG2 = alphaG * alphaG;

    const float Lambda_GGXV = NdotL * sqrt((-NdotV * alphaG2 + NdotV) * NdotV + alphaG2);
    const float Lambda_GGXL = NdotV * sqrt((-NdotL * alphaG2 + NdotL) * NdotL + alphaG2);

    return 0.5f / (Lambda_GGXV + Lambda_GGXL);
}

float D_GGX(float NdotH, float m)
{
    const float m2 = m * m;
    const float f = (NdotH * m2 - NdotH) * NdotH + 1;

    return m2 / (f * f);
}
