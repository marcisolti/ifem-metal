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

#include "Math.h"

using ID = uint32_t;

struct Transform {
    Math::Vector3 position, rotation, scale;
};

struct Material {
    Math::Vector3 baseColor;
    float smoothness, f0, f90;
    bool isMetal;
};

struct ShadedMesh {
    ID mesh;
    Material material = {{1,1,1}, 0.6, 0.3, 1.0, false};
};

class Entity {
public:
    Entity(const ShadedMesh& shadedMesh,
           const Transform& rootTransform = {{0,0,0}, {0,0,0}, {1,1,1}})
    : shadedMesh{shadedMesh}
    , rootTransform{rootTransform} {  }

    Transform rootTransform;
    ShadedMesh shadedMesh;
};

struct Light {};

struct Config {
    Math::Vector3 clearColor;
    bool isTrackpadPanning = false;
};

struct Scene {
    std::map<ID, Entity> entities;
    std::map<ID, Light> lights;
};

struct MeshToLoad {
    ID Id;
    std::string path;
};

struct World {
    Config config;
    Scene scene;
    std::vector<MeshToLoad> meshesToLoad;
};
