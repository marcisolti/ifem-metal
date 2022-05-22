//
//  Math.cpp
//  iFEM
//
//  Created by Marci Solti on 2021. 12. 29..
//  Copyright © 2021. Apple. All rights reserved.
//

#include "Math.h"

simd_float4x4 Matrix::Rotation(float x, float y, float z)
{
    simd_float4x4 result = matrix_identity_float4x4;

    float cosx = cosf(x);
    float sinx = sinf(x);

    result.columns[0][0] = cosx;
    result.columns[2][0] = sinx;
    result.columns[0][2] = -sinx;
    result.columns[2][2] = cosx;

    return result;
}

simd_float4x4 Matrix::Translation(float x, float y, float z)
{
    simd_float4x4 result = matrix_identity_float4x4;
    result.columns[3][0] = x;
    result.columns[3][1] = y;
    result.columns[3][2] = z;
    return result;
}

simd_float4x4 Matrix::Scaling(float x, float y, float z)
{
    simd_float4x4 result;
    result.columns[0][0] = x;
    result.columns[1][1] = y;
    result.columns[2][2] = z;
    result.columns[3][3] = 1.f;
    return result;
}

simd_float4x4 Matrix::Scaling(float value)
{
    simd_float4x4 result = matrix_scale(value, matrix_identity_float4x4);
    result.columns[3][3] = 1.f;
    return result;
}

simd_float4x4 Matrix::Projection(float fovy,
                                 float aspect,
                                 float near,
                                 float far)
{
    float ys = 1.f / tanf(0.5f * fovy);
    float xs = ys / aspect;
    float zs = far / (far-near);
    return simd_float4x4 { simd_float4{ xs, 0,  0,       0 },
                           simd_float4{ 0,  ys, 0,       0 },
                           simd_float4{ 0,  0,  zs,      1 },
                           simd_float4{ 0,  0, -near*zs, 0 }};
}

simd_float4x4 Matrix::View(const vector_float3& eye,
                           const vector_float3& lookAt,
                           const vector_float3& up)
{
    simd_float3 z = simd_normalize(lookAt - eye);
    simd_float3 x = simd_normalize(simd_cross(up, z));
    simd_float3 y = simd_cross(z, x);
    simd_float3 t = {-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye)};
    return
    simd_transpose(
           simd_float4x4 { simd_float4 { x.x, x.y, x.z, t.x },
                           simd_float4 { y.x, y.y, y.z, t.y },
                           simd_float4 { z.x, z.y, z.z, t.z },
                           simd_float4 { 0,   0,   0,   1   }});
}
