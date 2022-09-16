//
//  Mesh.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Mesh.h"

template<>
void Mesh<Geometry<Vertex, uint32_t>>::CreateBuffers(id<MTLDevice> device)
{
    vertexBuffer = [device newBufferWithLength:sizeof(Vertex) * geometry.vertices.size()
                                       options:MTLResourceStorageModeShared];
    indexBuffer = [device newBufferWithLength:sizeof(uint32_t) * geometry.indices.size()
                                      options:MTLResourceStorageModeShared];
}

template<>
void Mesh<Geometry<Vertex, uint32_t>>::UploadGeometry()
{
    memcpy(vertexBuffer.contents, geometry.vertices.data(), sizeof(Vertex) * geometry.vertices.size());
    memcpy(indexBuffer.contents, geometry.indices.data(), sizeof(uint32_t) * geometry.indices.size());
}

template<>
void Mesh<Geometry<Vertex, uint32_t>>::Draw(id<MTLRenderCommandEncoder> renderEncoder) const
{
    [renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:VertexInputIndexVertices];
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:geometry.indices.size()
                               indexType:MTLIndexTypeUInt32
                             indexBuffer:indexBuffer
                       indexBufferOffset:0];
}

