//
//  Entity.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Mesh.h"

#include <Metal/Metal.h>

class Entity
{
public:
    Entity(): modelMatrix{matrix_identity_float4x4} { }

    simd_float4x4 modelMatrix;

    void SetDisplacement(const std::vector<simd_float3>& u);
    void LoadGeometryFromFile(const std::string& fullPath, id<MTLDevice> device);
    void Draw(id<MTLRenderCommandEncoder> renderEncoder, const simd_float4x4& viewProjectionMatrix);
private:
    Mesh<Geometry<Vertex, uint32_t>> mesh;
    Geometry<Vertex, uint32_t> initGeometry;
};
