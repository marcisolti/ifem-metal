//
//  Simulator.hpp
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 25..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Solver.h"

#include <simd/simd.h>

class Simulator
{
public:
    Simulator() = default;
    ~Simulator() = default;

    void StartUp(const Config& config);
    void ShutDown();

    Result Step(const State& state);

private:
    Solver gSolver;
};
