//
//  Mesh.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Mesh.h"

template<>
void Mesh<Geometry<Vertex, uint32_t>>::UploadGeometry(id<MTLDevice> device)
{
    vertexBuffer = [device newBufferWithLength: geometry.VertexSize()
                                        options:MTLResourceStorageModeShared];
    indexBuffer = [device newBufferWithLength: geometry.IndexSize()
                                       options:MTLResourceStorageModeShared];

    memcpy(vertexBuffer.contents, geometry.VertexData(), geometry.VertexSize());
    memcpy(indexBuffer.contents, geometry.IndexData(), geometry.IndexSize());
}

template<>
void Mesh<Geometry<Vertex, uint32_t>>::Draw(id<MTLRenderCommandEncoder> renderEncoder)
{
    [renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:VertexInputIndexVertices];
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:geometry.IndexCount()
                               indexType:MTLIndexTypeUInt32
                             indexBuffer:indexBuffer
                       indexBufferOffset:0];
}

