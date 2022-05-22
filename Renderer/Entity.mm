//
//  Entity.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Entity.h"

#include "LoadOBJ.h"

void Entity::LoadGeometryFromFile(const std::string& filename, id<MTLDevice> device)
{
    mesh.geometry = LoadOBJ(filename);
    mesh.UploadGeometry(device);
}

void Entity::Draw(id<MTLRenderCommandEncoder> renderEncoder, const simd_float4x4& viewProjectionMatrix)
{
    const simd_float4x4 MVP = matrix_multiply(viewProjectionMatrix, modelMatrix);
    [renderEncoder setVertexBytes:&MVP
                           length:sizeof(MVP)
                          atIndex:VertexInputIndexMVP];
    mesh.Draw(renderEncoder);
}
