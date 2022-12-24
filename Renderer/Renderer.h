//
//  Renderer.h
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#pragma once

#include "Entity.h"

#include "Math.h"
#include "Mesh.h"

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

    void BeginFrame(MTKView* view, const Config& config);
    void EndFrame();

    void Update(std::vector<MeshToLoad>& meshesToLoad);
    void Draw(const Scene& scene);
    void SetViewportSize(CGSize size);
    void HandleMouseDragged(double deltaX, double deltaY, double deltaZ);
    void HandleKeyPressed(uint keyCode, bool keyUp);

    std::map<ID, Mesh>* GetMeshDirectory() { return &meshDirectory; }

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

    std::map<ID, Mesh> meshDirectory;
    struct {
        Mesh lightGeometry;
        id<MTLRenderPipelineState> lightGeometryPipelineState;
    } debug;

    Math::Vector3 eye, lookAt, up;
    Math::Matrix4 viewMatrix;
    Math::Matrix4 projectionMatrix;
    vector_uint2 viewportSize;
    struct {
        bool isPressed;
        uint key;
    } keyboardInput;
};
