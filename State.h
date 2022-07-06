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
    struct Simulator
    {
        std::string modelName;
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
