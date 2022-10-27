//
//  Entity.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 22..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <vector>
#include <string>
#include <map>

#include <simd/simd.h>

using ID = uint32_t;

struct Transform {
    simd::float3 position, rotation, scale;
};

class Entity {
public:
    Entity(std::vector<ID> meshes)
    : meshes{meshes} {}

    Transform transform;
    std::vector<ID> meshes;
};

struct Light {};

struct Config {
    float clearColor[3];
};

struct Scene {
    std::map<ID, Entity> entities;
    std::map<ID, Light> lights;
};

struct World {
    Config config;
    Scene scene;
};
