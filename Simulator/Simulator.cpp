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
const Result& Simulator::Step(const State& state)
{
    return {};
}
