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
    viewMatrix = Matrix::View(eye, lookAt, up);

    Mesh m{LoadOBJ("suz.obj")};
    m.CreateBuffers(device);
    m.UploadGeometry();

    meshDirectory.insert({GetID(), m});
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
        const simd_float3 pos = entity.transform.position;
        const simd_float4x4 MVP = matrix_multiply(matrix_multiply(projectionMatrix, viewMatrix), Matrix::Translation(pos[0], pos[1], pos[2]));
        [renderEncoder setVertexBytes:&MVP
                               length:sizeof(MVP)
                              atIndex:VertexInputIndexMVP];
        for (const auto& meshID : entity.meshes) {
            meshDirectory[meshID].Draw(renderEncoder);
        }
    }
}

void Renderer::SetViewportSize(CGSize size)
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;
    projectionMatrix = Matrix::Projection(54.4f * (M_PI / 180), (float)viewportSize.x/viewportSize.y, 0.01f, 1000.f);
}

void Renderer::HandleMouseDragged(double deltaX, double deltaY, double deltaZ)
{
    const simd_float3 forward = simd_normalize(lookAt - eye);
    const simd_float3 right = simd_normalize(simd_cross(forward, up));
    lookAt -=  20*(deltaX / viewportSize.x) * right;
    lookAt -=  20*(deltaY / viewportSize.y) * up;
    viewMatrix = Matrix::View(eye, lookAt, up);
}

void Renderer::HandleKeyPressed(uint keyCode)
{
    const simd_float3 forward = 1 * simd_normalize(lookAt - eye);
    const simd_float3 right = simd_normalize(simd_cross(forward, up));
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
    viewMatrix = Matrix::View(eye, lookAt, up);
}

