//
//  Entity.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Entity.h"

#include "Math.h"
#include "LoadOBJ.h"

#include <cmath>

void Entity::LoadGeometryFromFile(const std::string& filename, id<MTLDevice> device)
{
    mesh.geometry = LoadOBJ(filename);
    initGeometry = mesh.geometry;
    mesh.CreateBuffers(device);
    mesh.UploadGeometry();
}

void Entity::SetDisplacement(const std::vector<simd_float3>&)
{
    static float T = 0.f;
    T += 0.05;
    for (size_t i = 0; i < mesh.geometry.vertices.size(); ++i)
    {
        auto& v = mesh.geometry.vertices[i].position;
        v.x = initGeometry.vertices[i].position.x + std::sin(T + v.y * 3)/2;
    }

    // normal computation
    const auto& vertices = mesh.geometry.vertices;
    const auto& indices = mesh.geometry.indices;
    std::vector<simd_float3> normals(vertices.size(), simd_float3{0,0,0});

    for (size_t i = 0; i < indices.size() / 3; ++i)
    {
        uint32_t index0 = indices[3 * i + 0];
        uint32_t index1 = indices[3 * i + 1];
        uint32_t index2 = indices[3 * i + 2];

        simd_float3 a = vertices[index0].position;
        simd_float3 b = vertices[index1].position;
        simd_float3 c = vertices[index2].position;

        const simd_float3 ba = b - a;
        const simd_float3 ca = c - a;

        simd_float3 cross = simd_cross(ba, ca);
        cross *= 0.5 / simd_length(cross);

        normals[index0] += cross;
        normals[index1] += cross;
        normals[index2] += cross;
    }

    for (size_t i = 0; i < vertices.size(); ++i)
        mesh.geometry.vertices[i].normal = simd_normalize(normals[i]);

    mesh.UploadGeometry();
}

void Entity::Draw(id<MTLRenderCommandEncoder> renderEncoder, const simd_float4x4& viewProjectionMatrix)
{
    static float T = 0.f;
    T += 0.01f;
    modelMatrix = matrix_multiply(Matrix::Rotation(T), Matrix::Scaling(0.8f));

    FrameData frameData {
        modelMatrix, simd_inverse(modelMatrix), viewProjectionMatrix
    };

    [renderEncoder setVertexBytes:&frameData
                           length:sizeof(frameData)
                          atIndex:VertexInputIndexMVP];
    mesh.Draw(renderEncoder);
}
