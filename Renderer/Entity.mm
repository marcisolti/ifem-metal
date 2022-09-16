//
//  Entity.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Entity.h"

#include "LoadOBJ.h"

Entity Entity::LoadGeometryFromFile(const std::string& filename, id<MTLDevice> device)
{
    Entity ret;
    ret.mesh.geometry = LoadOBJ(filename);
    ret.mesh.CreateBuffers(device);
    ret.mesh.UploadGeometry();
    return ret;
}

void Entity::Draw(id<MTLRenderCommandEncoder> renderEncoder, const simd_float4x4& viewProjectionMatrix) const
{
    const simd_float4x4 MVP = matrix_multiply(viewProjectionMatrix, modelMatrix);
    [renderEncoder setVertexBytes:&MVP
                           length:sizeof(MVP)
                          atIndex:VertexInputIndexMVP];
    mesh.Draw(renderEncoder);
}
