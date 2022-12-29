//
//  Physics.cpp
//  iFEM
//
//  Created by Marton Solti on 2022. 12. 25..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Physics.h"

// SPDX-FileCopyrightText: 2021 Jorrit Rouwe
// SPDX-License-Identifier: MIT

// Jolt includes
#include <Jolt/RegisterTypes.h>
#include <Jolt/Core/Factory.h>
#include <Jolt/Physics/PhysicsSettings.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/Shape/SphereShape.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Body/BodyActivationListener.h>

// STL includes
#include <iostream>
#include <cstdarg>
#include <thread>

// Disable common warnings triggered by Jolt, you can use JPH_SUPPRESS_WARNING_PUSH / JPH_SUPPRESS_WARNING_POP to store and restore the warning state
JPH_SUPPRESS_WARNINGS

// All Jolt symbols are in the JPH namespace
using namespace JPH;

// If you want your code to compile using single or double precision write 0.0_r to get a Real value that compiles to double or float depending if JPH_DOUBLE_PRECISION is set or not.
using namespace JPH::literals;

// We're also using STL classes in this example
using namespace std;

// Callback for traces, connect this to your own trace function if you have one
static void TraceImpl(const char *inFMT, ...)
{
    // Format the message
    va_list list;
    va_start(list, inFMT);
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), inFMT, list);
    va_end(list);

    // Print to the TTY
    cout << buffer << endl;
}

#ifdef JPH_ENABLE_ASSERTS

// Callback for asserts, connect this to your own assert handler if you have one
static bool AssertFailedImpl(const char *inExpression, const char *inMessage, const char *inFile, uint inLine)
{
    // Print to the TTY
    cout << inFile << ":" << inLine << ": (" << inExpression << ") " << (inMessage != nullptr? inMessage : "") << endl;

    // Breakpoint
    return true;
};

#endif // JPH_ENABLE_ASSERTS

// Layer that objects can be in, determines which other objects it can collide with
// Typically you at least want to have 1 layer for moving bodies and 1 layer for static bodies, but you can have more
// layers if you want. E.g. you could have a layer for high detail collision (which is not used by the physics simulation
// but only if you do collision testing).
namespace Layers
{
    static constexpr uint8 NON_MOVING = 0;
    static constexpr uint8 MOVING = 1;
    static constexpr uint8 NUM_LAYERS = 2;
};

// Function that determines if two object layers can collide
static bool MyObjectCanCollide(ObjectLayer inObject1, ObjectLayer inObject2)
{
    switch (inObject1)
    {
    case Layers::NON_MOVING:
        return inObject2 == Layers::MOVING; // Non moving only collides with moving
    case Layers::MOVING:
        return true; // Moving collides with everything
    default:
        JPH_ASSERT(false);
        return false;
    }
};

// Each broadphase layer results in a separate bounding volume tree in the broad phase. You at least want to have
// a layer for non-moving and moving objects to avoid having to update a tree full of static objects every frame.
// You can have a 1-on-1 mapping between object layers and broadphase layers (like in this case) but if you have
// many object layers you'll be creating many broad phase trees, which is not efficient. If you want to fine tune
// your broadphase layers define JPH_TRACK_BROADPHASE_STATS and look at the stats reported on the TTY.
namespace BroadPhaseLayers
{
    static constexpr BroadPhaseLayer NON_MOVING(0);
    static constexpr BroadPhaseLayer MOVING(1);
    static constexpr uint NUM_LAYERS(2);
};

// BroadPhaseLayerInterface implementation
// This defines a mapping between object and broadphase layers.
class BPLayerInterfaceImpl final : public BroadPhaseLayerInterface
{
public:
                                    BPLayerInterfaceImpl()
    {
        // Create a mapping table from object to broad phase layer
        mObjectToBroadPhase[Layers::NON_MOVING] = BroadPhaseLayers::NON_MOVING;
        mObjectToBroadPhase[Layers::MOVING] = BroadPhaseLayers::MOVING;
    }

    virtual uint                    GetNumBroadPhaseLayers() const override
    {
        return BroadPhaseLayers::NUM_LAYERS;
    }

    virtual BroadPhaseLayer            GetBroadPhaseLayer(ObjectLayer inLayer) const override
    {
        JPH_ASSERT(inLayer < Layers::NUM_LAYERS);
        return mObjectToBroadPhase[inLayer];
    }

#if defined(JPH_EXTERNAL_PROFILE) || defined(JPH_PROFILE_ENABLED)
    virtual const char *            GetBroadPhaseLayerName(BroadPhaseLayer inLayer) const override
    {
        switch ((BroadPhaseLayer::Type)inLayer)
        {
        case (BroadPhaseLayer::Type)BroadPhaseLayers::NON_MOVING:    return "NON_MOVING";
        case (BroadPhaseLayer::Type)BroadPhaseLayers::MOVING:        return "MOVING";
        default:                                                    JPH_ASSERT(false); return "INVALID";
        }
    }
#endif // JPH_EXTERNAL_PROFILE || JPH_PROFILE_ENABLED

private:
    BroadPhaseLayer                    mObjectToBroadPhase[Layers::NUM_LAYERS];
};

// Function that determines if two broadphase layers can collide
static bool MyBroadPhaseCanCollide(ObjectLayer inLayer1, BroadPhaseLayer inLayer2)
{
    switch (inLayer1)
    {
    case Layers::NON_MOVING:
        return inLayer2 == BroadPhaseLayers::MOVING;
    case Layers::MOVING:
        return true;
    default:
        JPH_ASSERT(false);
        return false;
    }
}

// An example contact listener
class MyContactListener : public ContactListener
{
public:
    // See: ContactListener
    virtual ValidateResult    OnContactValidate(const Body &inBody1, const Body &inBody2, RVec3Arg inBaseOffset, const CollideShapeResult &inCollisionResult) override
    {
        cout << "Contact validate callback" << endl;

        // Allows you to ignore a contact before it is created (using layers to not make objects collide is cheaper!)
        return ValidateResult::AcceptAllContactsForThisBodyPair;
    }

    virtual void            OnContactAdded(const Body &inBody1, const Body &inBody2, const ContactManifold &inManifold, ContactSettings &ioSettings) override
    {
        cout << "A contact was added" << endl;
    }

    virtual void            OnContactPersisted(const Body &inBody1, const Body &inBody2, const ContactManifold &inManifold, ContactSettings &ioSettings) override
    {
        cout << "A contact was persisted" << endl;
    }

    virtual void            OnContactRemoved(const SubShapeIDPair &inSubShapePair) override
    {
        cout << "A contact was removed" << endl;
    }
};

// An example activation listener
class MyBodyActivationListener : public BodyActivationListener
{
public:
    virtual void        OnBodyActivated(const BodyID &inBodyID, uint64 inBodyUserData) override
    {
        cout << "A body got activated" << endl;
    }

    virtual void        OnBodyDeactivated(const BodyID &inBodyID, uint64 inBodyUserData) override
    {
        cout << "A body went to sleep" << endl;
    }
};

// A body activation listener gets notified when bodies activate and go to sleep
// Note that this is called from a job so whatever you do here needs to be thread safe.
// Registering one is entirely optional.
MyBodyActivationListener body_activation_listener;

// A contact listener gets notified when bodies (are about to) collide, and when they separate again.
// Note that this is called from a job so whatever you do here needs to be thread safe.
// Registering one is entirely optional.
MyContactListener contact_listener;

// Create mapping table from object layer to broadphase layer
// Note: As this is an interface, PhysicsSystem will take a reference to this so this instance needs to stay alive!
BPLayerInterfaceImpl broad_phase_layer_interface;


void Physics::Startup()
{
//     Register allocation hook
//    RegisterDefaultAllocator();

    // Install callbacks
    Trace = TraceImpl;
    JPH_IF_ENABLE_ASSERTS(AssertFailed = AssertFailedImpl;)

    // Create a factory
    Factory::sInstance = new Factory();

    // Register all Jolt physics types
    RegisterTypes();

    // This is the max amount of rigid bodies that you can add to the physics system. If you try to add more you'll get an error.
    // Note: This value is low because this is a simple test. For a real project use something in the order of 65536.
    const uint cMaxBodies = 1024;

    // This determines how many mutexes to allocate to protect rigid bodies from concurrent access. Set it to 0 for the default settings.
    const uint cNumBodyMutexes = 0;

    // This is the max amount of body pairs that can be queued at any time (the broad phase will detect overlapping
    // body pairs based on their bounding boxes and will insert them into a queue for the narrowphase). If you make this buffer
    // too small the queue will fill up and the broad phase jobs will start to do narrow phase work. This is slightly less efficient.
    // Note: This value is low because this is a simple test. For a real project use something in the order of 65536.
    const uint cMaxBodyPairs = 1024;

    // This is the maximum size of the contact constraint buffer. If more contacts (collisions between bodies) are detected than this
    // number then these contacts will be ignored and bodies will start interpenetrating / fall through the world.
    // Note: This value is low because this is a simple test. For a real project use something in the order of 10240.
    const uint cMaxContactConstraints = 1024;

    // Now we can create the actual physics system.
    physics_system.Init(cMaxBodies, cNumBodyMutexes, cMaxBodyPairs, cMaxContactConstraints, broad_phase_layer_interface, MyBroadPhaseCanCollide, MyObjectCanCollide);

    physics_system.SetBodyActivationListener(&body_activation_listener);
    physics_system.SetContactListener(&contact_listener);
}

void Physics::Shutdown()
{
    // The main way to interact with the bodies in the physics system is through the body interface. There is a locking and a non-locking
    // variant of this. We're going to use the locking version (even though we're not planning to access bodies from multiple threads)
    BodyInterface &body_interface = physics_system.GetBodyInterface();

    for (const auto& [entityID, bodyID] : bodyMap)
    {
        body_interface.RemoveBody(bodyID);
        body_interface.DestroyBody(bodyID);
    }
    bodyMap.clear();

    // Destroy the factory
    delete Factory::sInstance;
    Factory::sInstance = nullptr;
}

void Physics::RebuildPhysics(const Scene& scene)
{
    BodyInterface &body_interface = physics_system.GetBodyInterface();

    for (const auto& [entityID, bodyID] : bodyMap)
    {
        body_interface.RemoveBody(bodyID);
        body_interface.DestroyBody(bodyID);
    }
    bodyMap.clear();

    {
//        // Now you can interact with the dynamic body, in this case we're going to give it a velocity.
//        // (note that if we had used CreateBody then we could have set the velocity straight on the body before adding it to the physics system)
//        body_interface.SetLinearVelocity(sphere_id, Vec3(0.0f, -5.0f, 0.0f));

    }

    for (const auto& [entityID, entity] : scene.entities)
    {
        const auto& component = entity.physicsComponent;

        EMotionType type;
        ObjectLayer layer;
        switch (component.type) {
            case ::Static: {
                type = EMotionType::Static;
                layer = Layers::NON_MOVING;
            } break;
            case ::Dynamic: {
                type = EMotionType::Dynamic;
                layer = Layers::MOVING;
            } break;
            default: {
                assert(false);
            } break;
        }

        BodyID bodyID;
        switch (component.shape) {
            case ::Sphere: {
                // Now create a dynamic body to bounce on the floor
                // Note that this uses the shorthand version of creating and adding a body to the world
                const auto& pos = entity.rootTransform.position;
                BodyCreationSettings sphere_settings(new SphereShape(entity.rootTransform.scale.x()),
                                                     RVec3(pos.x(), pos.y(), pos.z()),
                                                     Quat::sIdentity(),
                                                     type,
                                                     layer);
                bodyID = body_interface.CreateAndAddBody(sphere_settings, EActivation::Activate);
            } break;
            case ::Box: {
                // Next we can create a rigid body to serve as the floor, we make a large box
                // Create the settings for the collision volume (the shape).
                // Note that for simple shapes (like boxes) you can also directly construct a BoxShape.
                const auto& scale = entity.rootTransform.scale;
                BoxShapeSettings floor_shape_settings(Vec3(scale.x(), scale.y(), scale.z()));

                // Create the shape
                ShapeSettings::ShapeResult floor_shape_result = floor_shape_settings.Create();
                ShapeRefC floor_shape = floor_shape_result.Get(); // We don't expect an error here, but you can check floor_shape_result for HasError() / GetError()

                // Create the settings for the body itself. Note that here you can also set other properties like the restitution / friction.
                const auto& pos = entity.rootTransform.position;
                BodyCreationSettings floor_settings(floor_shape,
                                                    RVec3(pos.x(), pos.y(), pos.z()),
                                                    Quat::sIdentity(),
                                                    type,
                                                    layer);

                // The main way to interact with the bodies in the physics system is through the body interface. There is a locking and a non-locking
                // variant of this. We're going to use the locking version (even though we're not planning to access bodies from multiple threads)
                BodyInterface &body_interface = physics_system.GetBodyInterface();

                // Create the actual rigid body
                Body* floor = body_interface.CreateBody(floor_settings); // Note that if we run out of bodies this can return nullptr
                bodyID = floor->GetID();

                // Add it to the world
                body_interface.AddBody(bodyID, EActivation::DontActivate);
            } break;
            default: {
                assert(false);
            } break;
        }
        bodyMap.insert({entityID, bodyID});
    }

    // Optional step: Before starting the physics simulation you can optimize the broad phase. This improves collision detection performance (it's pointless here because we only have 2 bodies).
    // You should definitely not call this every frame or when e.g. streaming in a new level section as it is an expensive operation.
    // Instead insert all new objects in batches instead of 1 at a time to keep the broad phase efficient.
    physics_system.OptimizeBroadPhase();
}

void Physics::Step(Scene& scene)
{
    ++step;

    // If you take larger steps than 1 / 60th of a second you need to do multiple collision steps in order to keep the simulation stable. Do 1 collision step per 1 / 60th of a second (round up).
    constexpr int cCollisionSteps = 1;

    // If you want more accurate step results you can do multiple sub steps within a collision step. Usually you would set this to 1.
    constexpr int cIntegrationSubSteps = 1;

    // Step the world
    physics_system.Update(cDeltaTime, cCollisionSteps, cIntegrationSubSteps, &temp_allocator, &job_system);

    BodyInterface &body_interface = physics_system.GetBodyInterface();
    for (auto& [entityID, entity] : scene.entities)
    {
        const auto& bodyID = bodyMap[entityID];

        RVec3 position = body_interface.GetCenterOfMassPosition(bodyID);
        entity.physicsComponent.currentTransform.position = {position.GetX(), position.GetY(), position.GetZ()};
    }
}
