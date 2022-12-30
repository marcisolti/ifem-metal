//
//  Math.cpp
//  iFEM
//
//  Created by Marci Solti on 2021. 12. 29..
//  Copyright © 2021. Apple. All rights reserved.
//

#include "Math.h"

Math::Matrix4 Math::Translation(float x, float y, float z)
{
    Matrix4 ret;
    ret <<
        1.f, 0.f, 0.f, x,
        0.f, 1.f, 0.f, y,
        0.f, 0.f, 1.f, z,
        0.f, 0.f, 0.f, 1.f;
    return ret.transpose(); // ??
}

Math::Matrix4 Math::Translation(const Math::Vector3& pos)
{
    return Math::Translation(pos.x(), pos.y(), pos.z());
}

Math::Matrix4 Math::Rotation(float x, float y, float z)
{
    const float cosx = cosf(x);
    const float sinx = sinf(x);

    Matrix4 ret;
    ret <<
        cosx, 0.f, sinx, 0.f,
        0.f,  1.f, 0.f,  0.f,
       -sinx, 0.f, cosx, 0.f,
        0.f,  0.f, 0.f,  1.f;
    return ret;
}

Math::Matrix4 Math::Rotation(const Math::Vector3& pos)
{
    return Math::Rotation(pos.x(), pos.y(), pos.z());
}

Math::Matrix4 Math::Scaling(const Math::Vector3& scale)
{
    return Math::Scaling(scale.x(), scale.y(), scale.z());
}

Math::Matrix4 Math::Scaling(float x, float y, float z)
{
    Matrix4 ret;
    ret <<
        x,   0.f, 0.f, 0.f,
        0.f, y,   0.f, 0.f,
        0.f, 0.f, z,   0.f,
        0.f, 0.f, 0.f, 1.f;
    return ret;
}

Math::Matrix4 Math::Scaling(float value)
{
    return Scaling(value, value, value);
}

Math::Matrix4 Math::Projection(float fovy,
                               float aspect,
                               float near,
                               float far)
{
    const float ys = 1.f / tanf(0.5f * fovy);
    const float xs = ys / aspect;
    const float zs = far / (far-near);

    Matrix4 ret;
    ret <<
        xs,  0.f,  0.f,     0.f,
        0.f, ys,   0.f,     0.f,
        0.f, 0.f,  zs,      1.f,
        0.f, 0.f, -near*zs, 0.f;
    return ret;
}

Math::Matrix4 Math::View(const Vector3& eye,
                         const Vector3& lookAt,
                         const Vector3& up)
{
    const Vector3 z = (lookAt - eye).normalized();
    const Vector3 x = up.cross(z).normalized();
    const Vector3 y = z.cross(x);
    const Vector3 t = {-x.dot(eye), -y.dot(eye), -z.dot(eye)};

    Matrix4 ret;
    ret <<
        x.x(), x.y(), x.z(), t.x(),
        y.x(), y.y(), y.z(), t.y(),
        z.x(), z.y(), z.z(), t.z(),
        0.f,   0.f,   0.f,   1.f;
    return ret.transpose();
}

simd_float4x4 Math::ToFloat4x4(const Matrix4& m)
{
    return {
        simd_float4{m(0,0),m(0,1),m(0,2),m(0,3)},
        simd_float4{m(1,0),m(1,1),m(1,2),m(1,3)},
        simd_float4{m(2,0),m(2,1),m(2,2),m(2,3)},
        simd_float4{m(3,0),m(3,1),m(3,2),m(3,3)}
    };
}

simd_float3 Math::ToFloat3(const Vector3& v)
{
    return {v(0), v(1), v(2)};
}

simd_float4 Math::ToFloat4(const Vector4& v)
{
    return {v(0), v(1), v(2), v(3)};
}
