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

struct Geometry
{
    std::vector<Vertex> vertices;
    std::vector<uint32_t> indices;
};
