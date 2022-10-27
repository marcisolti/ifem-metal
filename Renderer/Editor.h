//
//  Editor.h
//  iFEM
//
//  Created by Marci Solti on 2022. 08. 29..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

#include <map>

#include "Entity.h"

class Editor
{
public:
    Editor() = default;
    ~Editor() = default;

    void StartUp(MTKView* view, id<MTLDevice> device);
    void ShutDown();
    
    void BeginFrame(MTKView* view, MTLRenderPassDescriptor* currentRenderPassDescriptor);
    void Update(World& world);
    void Draw(id<MTLRenderCommandEncoder> renderEncoder, id<MTLCommandBuffer> commandBuffer);
};
