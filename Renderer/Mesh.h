//
//  Mesh.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Geometry.h"
#include "ShaderTypes.h"

#include <Metal/Metal.h>

template<typename Geometry>
class Mesh
{
public:
    Geometry geometry;

    Mesh() = default;
    ~Mesh() = default;
    Mesh(Geometry geometry) : geometry{geometry} {}

    void CreateBuffers(id<MTLDevice> device);
    void UploadGeometry();
    void Draw(id<MTLRenderCommandEncoder> renderEncoder);
private:
    id<MTLBuffer> vertexBuffer;
    id<MTLBuffer> indexBuffer;
};
