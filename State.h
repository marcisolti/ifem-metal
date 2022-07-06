//
//  Config.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 25..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <string>
#include <vector>
#include <simd/simd.h>

struct Config
{
    std::string bundlePath;
    
    struct Simulator
    {
        std::string modelName;
        double h;
        double magicConstant;
        int maxCGIteration;

        struct Material {
            double E, nu, rho;
        } material;

        double loadStep;
        uint32_t loadedVert;
        std::vector<uint32_t> BCs;
    } simulator;

    struct Renderer
    {

    } renderer;
};


struct State
{

};

struct Result
{
    std::vector<simd_float3> u;
};
