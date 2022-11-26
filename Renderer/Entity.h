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
    Math::Vector3 ambient, diffuse, specular;
};

struct ShadedMesh {
    Transform transform = {{0,0,0}, {0,0,0}, {1,1,1}};
    ID mesh;
    Material material;
};

class Entity {
public:
    Entity(std::vector<ShadedMesh> meshes)
    : meshes{meshes}
    , transform{{0,0,0}, {0,0,0}, {1,1,1}} {  }

    Transform transform;
    std::vector<ShadedMesh> meshes;
};

struct Light {};

struct Config {
    float clearColor[3];
};

struct AssetPaths {
    struct {
        ID Id;
        std::string path = "";
    } meshToLoad;
    std::map<ID, std::string> meshNames;
};

struct Scene {
    std::map<ID, Entity> entities;
    std::map<ID, Light> lights;
};

struct World {
    Config config;
    Scene scene;
    AssetPaths assetPaths;
};
