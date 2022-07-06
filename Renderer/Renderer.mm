//
//  Renderer.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Renderer.h"

#include "Math.h"

#include <iostream>

// The sample only supports the `MTLPixelFormatBGRA8Unorm` and
// `MTLPixelFormatR32Uint` formats.
static inline uint32_t sizeofPixelFormat(NSUInteger format)
{
    return ((format) == MTLPixelFormatBGRA8Unorm ? 4 :
            (format) == MTLPixelFormatR32Uint    ? 4 : 0);
}

void Renderer::StartUp(MTKView* mtkView, const Config& config)
{
    selectedVert = 0xFFFFFFFF;

    view = mtkView;

    device = view.device;

    ((CAMetalLayer*)view.layer).allowsNextDrawableTimeout = NO;

    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    view.clearDepth = 1.0;

    defaultLibrary = [device newDefaultLibrary];

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

    LoadScene(config);
}

void Renderer::ShutDown()
{
}

void Renderer::LoadScene(const Config& config)
{
    deformable.LoadGeometryFromFile(config.bundlePath + std::string{'/'} + config.simulator.modelName + ".veg.obj", device);
    surfaceMesh.LoadGeometryFromFile(config.bundlePath + std::string{'/'} + config.simulator.modelName + ".obj", device);
    surfaceMesh.LoadInterpolationWeights(config.bundlePath + std::string{'/'} + config.simulator.modelName + ".interp");
}

void Renderer::BeginFrame(MTKView* view)
{
    commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
}

void Renderer::EndFrame(MTKView* view, id<MTLRenderCommandEncoder> renderEncoder)
{
}

void Renderer::Draw(MTKView* view, const State& state, const Result& result)
{
    BeginFrame(view);

    if (shouldReadTexture)
    {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:indexRenderPassDescriptor];
        renderEncoder.label = @"Offscreen Render Pass";
        [renderEncoder setRenderPipelineState:indexPipelineState];
        [renderEncoder setDepthStencilState:depthStencilState];

        deformable.SetDisplacement(result.u);
        deformable.Draw(renderEncoder, viewProjectionMatrix);

        [renderEncoder endEncoding];
    }

    {
        MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
        assert(renderPassDescriptor != nil);

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, double(viewportSize.x), double(viewportSize.y), 0.0, 1.0 }];
        [renderEncoder setRenderPipelineState:pipelineState];
        [renderEncoder setDepthStencilState:depthStencilState];

//        deformable.Draw(renderEncoder, viewProjectionMatrix);
        surfaceMesh.SetDisplacement(result.u);
        surfaceMesh.Draw(renderEncoder, viewProjectionMatrix);

        [renderEncoder endEncoding];
    }

    if (shouldReadTexture)
    {
        MTLPixelFormat pixelFormat = indexTexture.pixelFormat;
        switch (pixelFormat)
        {
            case MTLPixelFormatBGRA8Unorm:
            case MTLPixelFormatR32Uint:
                break;
            default:
                assert("Unsupported pixel format.");
        }

        MTLRegion readRegion = MTLRegionMake2D(readPos.x-2, readPos.y-2, 4, 4);

        MTLOrigin readOrigin = MTLOriginMake(readRegion.origin.x, readRegion.origin.y, 0);
        MTLSize readSize = MTLSizeMake(readRegion.size.width, readRegion.size.height, 1);

        NSUInteger bytesPerPixel = sizeofPixelFormat(indexTexture.pixelFormat);
        NSUInteger bytesPerRow   = readSize.width * bytesPerPixel;
        NSUInteger bytesPerImage = readSize.height * bytesPerRow;

        readBuffer = [indexTexture.device newBufferWithLength:bytesPerImage options:MTLResourceStorageModeShared];

        assert(readBuffer);

        id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder copyFromTexture:indexTexture
                         sourceSlice:0
                         sourceLevel:0
                        sourceOrigin:readOrigin
                          sourceSize:readSize
                            toBuffer:readBuffer
                   destinationOffset:0
              destinationBytesPerRow:bytesPerRow
            destinationBytesPerImage:bytesPerImage];
        [blitEncoder endEncoding];


    }

    [commandBuffer presentDrawable:view.currentDrawable];

    [commandBuffer commit];

    if (shouldReadTexture)
    {
        // The app must wait for the GPU to complete the blit pass before it can
        // read data from _readBuffer.
        [commandBuffer waitUntilCompleted];
        
        uint32_t readValue = *(static_cast<uint32_t*>(readBuffer.contents));
        if (readValue == 0)
            selectedVert = 0xFFFFFFFF;
        else
            selectedVert = readValue;
        //        std::cout << '[' << std::to_string(pixels->red) << ' ' << std::to_string(pixels->green) << ' ' << std::to_string(pixels->blue) << ' ' << std::to_string(pixels->alpha) << "]\n";
        shouldReadTexture = false;
    }
}

void Renderer::SetViewportSize(CGSize size)
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;

    MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor new];
    texDescriptor.textureType = MTLTextureType2D;
    texDescriptor.width = size.width;
    texDescriptor.height = size.height;
    texDescriptor.pixelFormat = MTLPixelFormatR32Uint;
    texDescriptor.usage = MTLTextureUsageRenderTarget |
                          MTLTextureUsageShaderRead;
    indexTexture = [device newTextureWithDescriptor:texDescriptor];

    texDescriptor.pixelFormat = view.depthStencilPixelFormat;
    indexDepth = [device newTextureWithDescriptor:texDescriptor];

    indexRenderPassDescriptor = [MTLRenderPassDescriptor new];
    indexRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    indexRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    indexRenderPassDescriptor.depthAttachment.texture = indexDepth;
    indexRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    indexRenderPassDescriptor.colorAttachments[0].texture = indexTexture;
    indexRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    indexRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    indexRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    NSError *error;
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Offscreen Render Pipeline";
    pipelineStateDescriptor.sampleCount = 1;
    pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"indexVertexShader"];
    pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:@"indexFragmentShader"];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatR32Uint;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    indexPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    const simd_float4x4 V = Matrix::View(simd_float3{0,0,4}, simd_float3{0,0,0}, simd_float3{0,1,0});
    const simd_float4x4 P = Matrix::Projection(54.4f * (M_PI / 180), (float)viewportSize.x/viewportSize.y, 0.01f, 1000.f);
    viewProjectionMatrix = matrix_multiply(P, V);
}

void Renderer::SetReadPos(CGPoint pos)
{
    readPos.x = pos.x;
    readPos.y = pos.y;
    shouldReadTexture = true;
}
