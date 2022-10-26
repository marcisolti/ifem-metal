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
#include "Mesh.h"

class Editor
{
public:
    Editor() = default;
    ~Editor() = default;

    void StartUp(MTKView* view, id<MTLDevice> device, std::map<ID, Mesh>* meshDirectory);
    void ShutDown();
    
    void Update(World& world);

    void Draw(MTKView* view,
              MTLRenderPassDescriptor* currentRenderPassDescriptor,
              id<MTLRenderCommandEncoder> renderEncoder,
              id<MTLCommandBuffer> commandBuffer,
              World& world);
    
private:
    std::map<ID, Mesh>* meshDirectory = nullptr;
};
