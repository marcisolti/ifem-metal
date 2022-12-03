//
//  Renderer.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Renderer.h"

#include "Math.h"

#include "LoadOBJ.h"

#include "ID.h"

// MARK: Init

void Renderer::StartUp(MTKView* view)
{
    device = view.device;

    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    view.clearDepth = 1.0;

    id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];

    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    
    NSError *error;
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    assert(pipelineState);

    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthDescriptor.depthWriteEnabled = YES;
    depthStencilState = [device newDepthStencilStateWithDescriptor:depthDescriptor];

    commandQueue = [device newCommandQueue];

    LoadScene();
}

void Renderer::ShutDown()
{
}

void Renderer::LoadScene()
{
    eye = {0,0,4};
    lookAt = {0,0,0};
    up = {0,1,0};
    viewMatrix = Math::View(eye, lookAt, up);


}

void Renderer::Update(std::vector<MeshToLoad>& meshesToLoad)
{
    for (const auto& meshToLoad : meshesToLoad)
    {
        Mesh m{LoadOBJ(meshToLoad.path)};
        m.CreateBuffers(device);
        m.UploadGeometry();

        meshDirectory.insert({meshToLoad.Id, m});
    }
    if (!meshesToLoad.empty()) meshesToLoad.clear();
}

// MARK: Drawing

void Renderer::BeginFrame(MTKView* view, const Config& config)
{
    view.clearColor = MTLClearColorMake(config.clearColor[0], config.clearColor[1], config.clearColor[2], 1.0);
    this->view = view;

    commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    currentPassDescriptor = view.currentRenderPassDescriptor;
    assert(currentPassDescriptor != nil);

    renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:currentPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, double(viewportSize.x), double(viewportSize.y), 0.0, 1.0 }];
    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setDepthStencilState:depthStencilState];

}

void Renderer::EndFrame()
{
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

void Renderer::Draw(const Scene& scene)
{
    for (const auto& [entityID, entity] : scene.entities) {
        for (const auto& shadedMesh : entity.meshes) {
            using namespace Math;
            const auto& transform = entity.transform;
            const auto modelMatrix = Scaling(transform.scale.x()) * Rotation(transform.rotation) * Translation(transform.position);
            VertexData vertexData = {
                .modelMatrix =    ToFloat4x4(modelMatrix),
                .modelMatrixInv = ToFloat4x4(modelMatrix.inverse()),
                .viewProjMatrix = ToFloat4x4(viewMatrix * projectionMatrix),
                .eyePos =         ToFloat3(eye)
            };

            FragmentData fragmentData = {
                .color = ToFloat3(shadedMesh.material.diffuse)
            };

            [renderEncoder setVertexBytes:&vertexData
                                   length:sizeof(vertexData)
                                  atIndex:VertexInputIndexFrameData];
            [renderEncoder setFragmentBytes:&fragmentData
                                   length:sizeof(fragmentData)
                                  atIndex:FragmentInputIndexFrameData];
            meshDirectory[shadedMesh.mesh].Draw(renderEncoder);
        }
    }
}

void Renderer::SetViewportSize(CGSize size)
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;
    projectionMatrix = Math::Projection(54.4f * (M_PI / 180), (float)viewportSize.x/viewportSize.y, 0.01f, 1000.f);
}

void Renderer::HandleMouseDragged(double deltaX, double deltaY, double deltaZ)
{
    using namespace Math;
    const Vector3 forward = (lookAt - eye).normalized();
    const Vector3 right = forward.cross(up).normalized();
    lookAt -=  20*(deltaX / viewportSize.x) * right;
    lookAt -=  20*(deltaY / viewportSize.y) * up;
    viewMatrix = View(eye, lookAt, up);
}

void Renderer::HandleKeyPressed(uint keyCode)
{
    using namespace Math;
    const Vector3 forward = 1 * (lookAt - eye).normalized();
    const Vector3 right = forward.cross(up).normalized();
    if(keyCode == 0) // W
    {
        eye += forward;
        lookAt += forward;
    }
    if(keyCode == 1) // A
    {
        eye += right;
        lookAt += right;
    }
    if(keyCode == 2) // S
    {
        eye -= forward;
        lookAt -= forward;
    }
    if(keyCode == 3) // D
    {
        eye -= right;
        lookAt -= right;
    }
    viewMatrix = View(eye, lookAt, up);
}

