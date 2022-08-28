//
//  Renderer.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Renderer.h"

#include "Math.h"

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
    staticGeometry.LoadGeometryFromFile(std::string{"suz.obj"}, device);
}

void Renderer::BeginFrame(MTKView* view)
{
    this->view = view;

    commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    assert(renderPassDescriptor != nil);

    renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
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

void Renderer::Draw()
{
    staticGeometry.Draw(renderEncoder, viewProjectionMatrix);
}

void Renderer::SetViewportSize(CGSize size)
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;

    const simd_float4x4 V = Matrix::View(simd_float3{0,0,4}, simd_float3{0,0,0}, simd_float3{0,1,0});
    const simd_float4x4 P = Matrix::Projection(54.4f * (M_PI / 180), (float)viewportSize.x/viewportSize.y, 0.01f, 1000.f);
    viewProjectionMatrix = matrix_multiply(P, V);
}
