//
//  Renderer.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Entity.h"

#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

#include <string>
#include <map>

class Renderer
{
public:
    Renderer() = default;
    ~Renderer() = default;

    void StartUp(MTKView* view);
    void ShutDown();

    void BeginFrame(MTKView* view);
    void EndFrame();

    void Draw();
    void SetViewportSize(CGSize size);

    void AddEntity(const std::pair<uint32_t, Entity>& entity) { entityDirectory.insert(entity); }

    id<MTLRenderCommandEncoder> GetRenderEncoder() const { return renderEncoder; }
    id<MTLCommandBuffer>        GetCommandBuffer() const { return commandBuffer; }
    id<MTLDevice>               GetDevice() const { return device; }
    MTLRenderPassDescriptor*    GetCurrentPassDescriptor() const { return currentPassDescriptor; }

private:
    void LoadScene();

    id<MTLDevice> device;

    MTKView* view;

    id<MTLCommandQueue> commandQueue;
    id<MTLCommandBuffer> commandBuffer;

    id<MTLRenderCommandEncoder> renderEncoder;

    MTLRenderPassDescriptor* currentPassDescriptor;
    id<MTLRenderPipelineState> pipelineState;
    id<MTLDepthStencilState> depthStencilState;

    std::map<uint32_t, Entity> entityDirectory;

    simd_float4x4 viewProjectionMatrix;
    vector_uint2 viewportSize;

};
