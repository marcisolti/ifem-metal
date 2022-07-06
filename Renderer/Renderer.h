//
//  Renderer.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Entity.h"
#include "../State.h"

#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

#include <string>

class Renderer
{
public:
    Renderer() = default;
    ~Renderer() = default;

    void StartUp(MTKView* view, const Config& config);
    void ShutDown();

    void Draw(MTKView* view, const State& state, const Result& result);

    void SetViewportSize(CGSize size);

private:
    void LoadScene(const Config& config);
    id<MTLRenderCommandEncoder> BeginFrame(MTKView* view);
    void EndFrame(MTKView* view, id<MTLRenderCommandEncoder> renderEncoder);

    id<MTLDevice> device;

    id<MTLCommandQueue> commandQueue;
    id<MTLCommandBuffer> commandBuffer;

    id<MTLRenderPipelineState> pipelineState;
    id<MTLDepthStencilState> depthStencilState;

    Entity deformable;

    simd_float4x4 viewProjectionMatrix;
    vector_uint2 viewportSize;

};
