//
//  Renderer.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

class Renderer
{
public:
    Renderer() = default;
    ~Renderer() = default;

    void StartUp(MTKView* view);
    void ShutDown();
    void Draw(MTKView* view);
    void SetViewportSize(CGSize size);

private:
    id<MTLDevice> device;

    id<MTLRenderPipelineState> pipelineState;
    id<MTLCommandQueue> commandQueue;

    vector_uint2 viewportSize;
};
