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

    void StartUp(MTKView* mtkView, const Config& config);
    void ShutDown();

    void Draw(MTKView* mtkView, const State& state, const Result& result);

    void SetViewportSize(CGSize size);
    void SetReadPos(CGPoint pos);

    uint32_t GetSelectedVert() { return selectedVert; }

private:
    void LoadScene(const Config& config);
    void BeginFrame(MTKView* view);
    void EndFrame(MTKView* view, id<MTLRenderCommandEncoder> renderEncoder);

    id<MTLDevice> device;
    MTKView* view;

    id<MTLLibrary> defaultLibrary;
    id<MTLCommandQueue> commandQueue;
    id<MTLCommandBuffer> commandBuffer;

    id<MTLRenderPipelineState> pipelineState;
    id<MTLDepthStencilState> depthStencilState;

    id<MTLRenderPipelineState> indexPipelineState;
    id<MTLTexture> indexTexture;
    id<MTLTexture> indexDepth;
    MTLRenderPassDescriptor* indexRenderPassDescriptor;

    id<MTLBuffer> readBuffer;
    vector_float2 readPos;
    uint32_t selectedVert;
    bool shouldReadTexture = false;

    Entity surfaceMesh;
    Entity deformable;

    simd_float4x4 viewProjectionMatrix;
    vector_uint2 viewportSize;

};
