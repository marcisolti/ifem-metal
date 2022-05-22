//
//  ShaderTypes.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <simd/simd.h>

typedef enum VertexInputIndex
{
    VertexInputIndexVertices = 0,
    VertexInputIndexMVP      = 1,
} VertexInputIndex;

typedef struct
{
    vector_float3 position;
    vector_float3 normal;
} Vertex;
