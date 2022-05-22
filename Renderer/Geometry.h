//
//  Geometry.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <vector>

template<typename VertexType,
         typename IndexType>
struct Geometry
{
    std::vector<VertexType> vertices;
    std::vector<IndexType> indices;
};
