//
//  LoadOBJ.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Geometry.h"

#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

struct Index { uint32_t v[3], n[3], uv[3]; };

Geometry LoadOBJ(const std::string& path)
{
//    // open file
//    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
//    std::ifstream f(std::string{[bundlePath UTF8String]} + std::string{'/'} + path);

    std::ifstream f(path);

    if (!f.is_open()) {
        std::printf("CANNOT OPEN FILE");
        std::exit(420);
    }

    // parse OBJ
    std::vector<std::string> lines;
    std::string line;

    while (std::getline(f, line))
        lines.push_back(line);

    std::vector<simd_float3> vertices;
    std::vector<simd_float3> normals;
    std::vector<simd_float2> uvs;
    std::vector<Index>       indices;

    for (const auto& i : lines)
    {
        std::stringstream line{i};
        std::string type;
        line >> type;
        if(type == "v")
        {
            float x, y, z;
            line >> x >> y >> z;
            vertices.push_back(simd_float3{x,y,z});
        }
        else if(type == "vt")
        {
            float u, v;
            line >> u >> v;
            uvs.push_back(simd_float2{u,v});
        }

        else if(type == "vn")
        {
            float x, y, z;
            line >> x >> y >> z;
            normals.push_back(simd_float3{x,y,z});
        }
        else if(type == "f")
        {
            Index i;
            char c;
            for (int j = 0; j < 3; ++j) {
                line >> i.v[j] >> c >> i.uv[j] >> c >> i.n[j];
            }
            indices.push_back(i);
        }
    }

    // generate output
    std::vector<Vertex>   outVertices;
    std::vector<uint32_t> outIndices;
    outVertices.reserve(vertices.size());
    outIndices.reserve(indices.size());

    for (const auto& v : vertices)
        outVertices.emplace_back(Vertex{{v},{}});

    for (const auto& index : indices)
    {
        for (int j = 0; j < 3; ++j)
        {
            uint32_t vIndex = index.v[j] - 1;
            uint32_t nIndex = index.n[j] - 1;
            uint32_t uvIndex = index.uv[j] - 1;

            outVertices[vIndex].normal = normals[nIndex];
            outIndices.emplace_back(vIndex);
        }
    }
    return { outVertices, outIndices };
};
