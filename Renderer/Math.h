//
//  Math.h
//  iFEM
//
//  Created by Marci Solti on 2021. 12. 29..
//  Copyright © 2021. Apple. All rights reserved.
//

#pragma once

#include <simd/simd.h>

namespace Matrix
{
    simd_float4x4 Rotation(float x = 0.f, float y = 0.f, float z = 0.f);
    simd_float4x4 Translation(float x = 0.f, float y = 0.f, float z = 0.f);
    simd_float4x4 Scaling(float x, float y, float z);
    simd_float4x4 Scaling(float value);
    simd_float4x4 Projection(float fovy, float aspect, float near, float far);
    simd_float4x4 View(const simd_float3& eye, const simd_float3& ahead, const simd_float3& up);
}
