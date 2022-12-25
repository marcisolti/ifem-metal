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
    view.sampleCount = 4;

    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    view.clearDepth = 1.0;

    id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];

    // pipeline state
    {
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"PBRVertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"PBRFragmentShader"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
        pipelineStateDescriptor.rasterSampleCount = 4;

        NSError *error;
        pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                               error:&error];
        assert(pipelineState);
    }

    // debug light pipeline state
    {
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"DebugLightVertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"DebugLightFragmentShader"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
        pipelineStateDescriptor.rasterSampleCount = 4;

        NSError *error;
        debug.lightGeometryPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                                  error:&error];
        assert(debug.lightGeometryPipelineState);
    }


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

    debug.lightGeometry = Mesh({
        .vertices = {
            {{1, 1, -1},    {0, 0, -1}, {0,0}},
            {{1, -1, -1},   {0, 0, -1}, {0,0}},
            {{1, 1, 1},     {1, 0, 0}, {0,0}},
            {{1, -1, 1},    {1, 0, 0}, {0,0}},
            {{-1, 1, -1},   {0, 0, -1}, {0,0}},
            {{-1, -1, -1},  {-1, 0, 0}, {0,0}},
            {{-1, 1, 1},    {-1, 0, 0}, {0,0}},
            {{-1, -1, 1},   {0, -1, 0}, {0,0}},
        },
        .indices = {
            4, 2, 0, 2, 7, 3, 6, 5, 7, 1, 7, 5, 0, 3, 1, 4, 1, 5, 4, 6, 2, 2, 6, 7, 6, 4, 5, 1, 3, 7, 0, 2, 3, 4, 0, 1
        }
    });
    debug.lightGeometry.CreateBuffers(device);
    debug.lightGeometry.UploadGeometry();
}

void Renderer::Update(std::vector<MeshToLoad>& meshesToLoad)
{
    if (meshesToLoad.empty()) return;

    for (const auto& meshToLoad : meshesToLoad)
    {
        Mesh m{LoadOBJ(meshToLoad.path)};
        m.CreateBuffers(device);
        m.UploadGeometry();

        meshDirectory.insert({meshToLoad.Id, m});
    }
    meshesToLoad.clear();
}

// MARK: Drawing

void Renderer::BeginFrame(MTKView* view, const Config& config)
{
    view.clearColor = MTLClearColorMake(config.clearColor(0), config.clearColor(1), config.clearColor(2), 1.0);
    this->view = view;

    commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    currentPassDescriptor = view.currentRenderPassDescriptor;
    assert(currentPassDescriptor != nil);

    renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:currentPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, double(viewportSize.x), double(viewportSize.y), 0.0, 1.0 }];
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
    if (keyboardInput.isPressed)
    {
        using namespace Math;
        const Vector3 forward = 0.05f * (lookAt - eye).normalized();
        const Vector3 right = 0.05f * forward.cross(up).normalized();

        auto keyCode = keyboardInput.key;
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
        viewMatrix = Math::View(eye, lookAt, up);
    }

    FragmentData fragmentData;
    fragmentData.numLights = uint32_t(scene.lights.size());

    uint32_t lightCounter = 0;
    for (const auto& [lightID, light] : scene.lights)
    {
        using namespace Math;
        fragmentData.lights[lightCounter++] = {
            .position = ToFloat3(light.position),
            .intensity = ToFloat3(light.intensity * light.color)
        };
    }
    assert(lightCounter == fragmentData.numLights);
    assert(fragmentData.numLights <= MAX_NUM_LIGHTS);

    [renderEncoder setRenderPipelineState:pipelineState];
    for (const auto& [entityID, entity] : scene.entities)
    {
        using namespace Math;
        const auto& rootTransform = entity.rootTransform;
        const auto& shadedMesh = entity.shadedMesh;
        const auto modelMatrix =
            Scaling(rootTransform.scale.x()) *
            Rotation(rootTransform.rotation) *
            Translation(rootTransform.position);

        VertexData vertexData = {
            .modelMatrix =    ToFloat4x4(modelMatrix),
            .modelMatrixInv = ToFloat4x4(modelMatrix.inverse()),
            .viewProjMatrix = ToFloat4x4(viewMatrix * projectionMatrix),
            .eyePos =         ToFloat3(eye)
        };

        const auto& material = shadedMesh.material;
        fragmentData.baseColor = ToFloat3(material.baseColor);
        fragmentData.smoothness = material.smoothness;
        fragmentData.f0 = material.f0;
        fragmentData.f90 = material.f90;
        fragmentData.isMetal = material.isMetal;

        [renderEncoder setVertexBytes:&vertexData
                               length:sizeof(vertexData)
                              atIndex:VertexInputIndexFrameData];
        [renderEncoder setFragmentBytes:&fragmentData
                               length:sizeof(fragmentData)
                              atIndex:FragmentInputIndexFrameData];
        meshDirectory[shadedMesh.mesh].Draw(renderEncoder);
    }

    [renderEncoder setRenderPipelineState:debug.lightGeometryPipelineState];
    for (const auto& [lightID, light] : scene.lights)
    {
        using namespace Math;
        const auto modelMatrix =
            Scaling(0.2f) *
            Translation(light.position);

        const auto MVP = ToFloat4x4(modelMatrix * viewMatrix * projectionMatrix);
        const auto color = ToFloat3(light.color);

        [renderEncoder setVertexBytes:&MVP
                               length:sizeof(MVP)
                              atIndex:VertexInputIndexFrameData];
        [renderEncoder setFragmentBytes:&color
                               length:sizeof(color)
                              atIndex:FragmentInputIndexFrameData];
        debug.lightGeometry.Draw(renderEncoder);
    }
}

void Renderer::SetViewportSize(CGSize size)
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;
    projectionMatrix = Math::Projection(54.4f * (M_PI / 180), float(viewportSize.x/viewportSize.y), 0.01f, 1000.f);
}

void Renderer::HandleMouseDragged(double deltaX, double deltaY, double deltaZ)
{
    using namespace Math;
    const Vector3 forward = (lookAt - eye).normalized();
    const Vector3 right = forward.cross(up).normalized();
    lookAt -= 20 * (deltaX / viewportSize.x) * right;
    lookAt -= 20 * (deltaY / viewportSize.y) * up;
    viewMatrix = View(eye, lookAt, up);
}

void Renderer::HandleKeyPressed(uint keyCode, bool keyUp)
{
    keyboardInput = { !keyUp, keyCode };
}
