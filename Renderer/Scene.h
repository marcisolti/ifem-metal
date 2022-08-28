//
//  Scene.h
//  iFEM
//
//  Created by Marci Solti on 2022. 08. 11..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <vector>
#include <map>

struct Transformation;
struct Geometry;
struct Texture;
struct Shader;
enum TextureType;

struct Mesh {
    Transformation t;
    Shader shader;
    Geometry geometry;
    std::map<TextureType, Texture> texture;
};

struct Entity {
    Transformation t;
    std::vector<Mesh> meshes;
};

struct Light {
    Transformation t;
    
}

struct Scene {

};
