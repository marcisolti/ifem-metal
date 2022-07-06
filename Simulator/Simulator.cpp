//
//  Simulator.cpp
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 25..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Simulator.h"

void Simulator::StartUp(const Config& config)
{
    gSolver.StartUp(config);
}

void Simulator::ShutDown()
{
}

Result Simulator::Step(const State& state)
{
    const Vec& u = gSolver.Step();
    Result res;
    res.u.reserve(u.size() / 3);
    for (size_t i = 0; i < u.size() / 3; ++i)
    {
        res.u.emplace_back(simd_float3{
            float(u(3 * i + 0)),
            float(u(3 * i + 1)),
            float(u(3 * i + 2))
        });
    }

    return res;
}
