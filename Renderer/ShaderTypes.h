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
    VertexInputIndexVertices    = 0,
    VertexInputIndexFrameData   = 1,
} VertexInputIndex;

typedef enum FragmentInputIndex
{
    FragmentInputIndexFrameData = 0,
} FragmentInputIndex;

typedef struct {
    matrix_float4x4 MVP;
} VertexData;

typedef struct {
    vector_float3 color;
} FragmentData;

typedef struct
{
    vector_float3 position;
    vector_float3 normal;
} Vertex;
