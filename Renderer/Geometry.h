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
struct Geometry
{
    Geometry() = default;

    Geometry(std::vector<VertexType> vertices, std::vector<IndexType> indices = {})
    : vertices{vertices}
    , indices{indices}
    { }

    std::vector<VertexType> vertices;
    std::vector<IndexType> indices;
};
