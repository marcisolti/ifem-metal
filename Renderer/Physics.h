//
//  Physics.h
//  iFEM
//
//  Created by Marton Solti on 2022. 12. 25..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

// The Jolt headers don't include Jolt.h. Always include Jolt.h before including any other Jolt header.
// You can use Jolt.h in your precompiled header to speed up compilation.
#include <Jolt/Jolt.h>
#include <Jolt/Physics/PhysicsSystem.h>

#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Core/JobSystemThreadPool.h>

#include <thread>

struct World;
struct PhysicsComponentAdded;

class Physics {
public:
    Physics()
    : temp_allocator(10 * 1024 * 1024)
    , job_system(JPH::cMaxPhysicsJobs, JPH::cMaxPhysicsBarriers, std::thread::hardware_concurrency() - 1)
    {  }
    ~Physics() = default;

    void Startup();
    void Shutdown();

    void Update(std::vector<PhysicsComponentAdded>& componentsAdded);
    void StepAndPackage(World& world);

private:
    JPH::PhysicsSystem physics_system;

    std::vector<JPH::BodyID> bodies;

    // We need a temp allocator for temporary allocations during the physics update. We're
    // pre-allocating 10 MB to avoid having to do allocations during the physics update.
    // B.t.w. 10 MB is way too much for this example but it is a typical value you can use.
    // If you don't want to pre-allocate you can also use TempAllocatorMalloc to fall back to
    // malloc / free.
    JPH::TempAllocatorImpl temp_allocator;

    // We need a job system that will execute physics jobs on multiple threads. Typically
    // you would implement the JobSystem interface yourself and let Jolt Physics run on top
    // of your own job scheduler. JobSystemThreadPool is an example implementation.
    JPH::JobSystemThreadPool job_system;

    // We simulate the physics world in discrete time steps. 60 Hz is a good rate to update the physics system.
    static constexpr float cDeltaTime = 1.0f / 60.0f;

    uint step = 0;
};
