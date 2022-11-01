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

// Define these only in *one* .cc file.
#define TINYGLTF_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
// #define TINYGLTF_NOEXCEPTION // optional. disable exception handling.
#include "tiny_gltf.h"

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

    tinygltf::Model model;
    tinygltf::TinyGLTF loader;
    std::string err;
    std::string warn;

    // open file
    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
    auto path = std::string{[bundlePath UTF8String]} + std::string{"/BarramundiFish.glb"};
    bool ret = loader.LoadBinaryFromFile(&model, &err, &warn, path); // for binary glTF(.glb)

    if (!warn.empty()) {
        printf("Warn: %s\n", warn.c_str());
    }

    if (!err.empty()) {
        printf("Err: %s\n", err.c_str());
    }

    if (!ret) {
        printf("Failed to parse glTF\n");
        std::terminate();
    }

//    const tinygltf::Scene &scene = model.scenes[model.defaultScene];
//    for (size_t i = 0; i < scene.nodes.size(); ++i)
//    {
//        assert((scene.nodes[i] >= 0) && (scene.nodes[i] < model.nodes.size()));
//        const tinygltf::Node node = model.nodes[scene.nodes[i]];
//        for (size_t j = 0; j < model.bufferViews.size(); ++j) {
//            const tinygltf::BufferView &bufferView = model.bufferViews[j];
//            const tinygltf::Buffer &buffer = model.buffers[bufferView.buffer];
//        }
//    }

    std::vector<float> pos;
    std::vector<float> normal;
    std::vector<float> uv;
    std::vector<int> indices;
    std::vector<Vertex> vertices;
    for (const auto& mesh : model.meshes) {
        for (const auto& primitive : mesh.primitives) {

            for (const auto& [attributeName, accessorIndex] : primitive.attributes) {
                tinygltf::Accessor accessor = model.accessors[accessorIndex];
                tinygltf::BufferView bufferView = model.bufferViews[accessor.bufferView];
                tinygltf::Buffer buffer = model.buffers[bufferView.buffer];
                uint8_t* first = buffer.data.data() + bufferView.byteOffset;
                uint8_t* last = first + bufferView.byteLength;
                if (attributeName == "POSITION") {
                    std::copy((float*)first, (float*)last, std::back_inserter(pos));
                } else if (attributeName == "NORMAL") {
                    std::copy((float*)first, (float*)last, std::back_inserter(normal));
                } else if (attributeName == "TEXCOORD_0") {
                    std::copy((float*)first, (float*)last, std::back_inserter(uv));
                }
            }

            tinygltf::Accessor indexAccessor = model.accessors[primitive.indices];
            tinygltf::BufferView indexBufferView = model.bufferViews[indexAccessor.bufferView];
            tinygltf::Buffer indexBuffer = model.buffers[indexBufferView.buffer];
//            uint8_t* first = indexBuffer.data.data() + indexBufferView.byteOffset;
//            uint8_t* last = first + indexBufferView.byteLength;
//            int size = int((first - last) / indexAccessor.count);
            const int* first = reinterpret_cast<const int*>(&indexBuffer.data[indexBufferView.byteOffset + indexAccessor.byteOffset]);
            const int* last = reinterpret_cast<const int*>(&indexBuffer.data[indexBufferView.byteOffset + indexAccessor.byteOffset + indexAccessor.byteOffset]);
            std::copy(first, last, std::back_inserter(indices));

            assert(pos.size() % 3 == 0);
            assert(indices.size() % 3 == 0);
            assert(normal.size() % 3 == 0);
            assert(uv.size() % 2 == 0);

            for (size_t i = 0; i < pos.size() / 3; ++i)
                vertices.push_back({{pos[3 * i + 0],
                                     pos[3 * i + 1],
                                     pos[3 * i + 2]},

                                    {1,1,1}});
//            for (const auto& index : indices)
//            {
//                for (int j = 0; j < 3; ++j)
//                {
//                    uint32_t vIndex = index.v[j] - 1;
//                    uint32_t nIndex = index.n[j] - 1;
//                    uint32_t uvIndex = index.uv[j] - 1;
//
//                    outVertices[vIndex].normal = normals[nIndex];
//                    outIndices.emplace_back(vIndex);
//                }
//            }
        }
    }

//    Mesh m{{vertices, indices}};
//    m.CreateBuffers(device);
//    m.UploadGeometry();

//    Mesh m(LoadOBJ("suz.obj"));
//    m.CreateBuffers(device);
//    m.UploadGeometry();

//    meshDirectory.insert({GetID(), m});
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

