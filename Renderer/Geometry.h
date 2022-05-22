//
//  Geometry.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "ShaderTypes.h"

#include <vector>

template<typename VertexType,
         typename IndexType>
class Geometry
{
public:
    Geometry() = default;

    Geometry(std::vector<VertexType> vertices, std::vector<IndexType> indices = {})
    : vertices{vertices}
    , indices{indices}
    { }

    void PushVertex(VertexType i) { vertices.push_back(i); }
    void PushIndex(IndexType v) { indices.push_back(v); }

    void SetVertices(const std::vector<VertexType>& v) { vertices = v; }
    void SetIndices(const std::vector<IndexType>& i) { indices = i; }

    VertexType* VertexData() { return vertices.data(); }
    VertexType* VertexData() const { return vertices.data(); }
    IndexType* IndexData() { return indices.data(); }
    IndexType* IndexData() const { return indices.data(); }

    size_t VertexSize() const { return sizeof(VertexType) * vertices.size(); }
    size_t IndexSize() const { return sizeof(IndexType) * indices.size(); }
    size_t IndexCount() const { return indices.size(); }

private:
    std::vector<VertexType> vertices;
    std::vector<IndexType> indices;
};
