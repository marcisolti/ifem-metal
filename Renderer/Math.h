//
//  Math.h
//  iFEM
//
//  Created by Marci Solti on 2021. 12. 29..
//  Copyright © 2021. Apple. All rights reserved.
//

#pragma once

#include <simd/simd.h>

#include <Eigen/Dense>

namespace Math
{
    using Matrix4 = Eigen::Matrix<float, 4, 4>;

    using Vector4 = Eigen::Vector<float, 4>;
    using Vector3 = Eigen::Vector<float, 3>;

    Matrix4 Rotation(float x, float y, float z);
    Matrix4 Rotation(const Math::Vector3& rot);

    Matrix4 Translation(float x, float y, float z);
    Matrix4 Translation(const Math::Vector3& pos);

    Matrix4 Scaling(float x, float y, float z);
    Matrix4 Scaling(const Math::Vector3& scale);
    Matrix4 Scaling(float value);

    Matrix4 Projection(float fovy, float aspect, float near, float far);
    Matrix4 View(const Vector3& eye, const Vector3& ahead, const Vector3& up);

    simd_float4x4 ToFloat4x4(const Matrix4& m);
    simd_float3 ToFloat3(const Vector3& v);
    simd_float4 ToFloat4(const Vector4& v);
}
