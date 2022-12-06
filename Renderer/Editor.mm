//
//  Editor.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 08. 29..
//  Copyright © 2022. Apple. All rights reserved.
//

#include "Editor.h"

#include "ID.h"

#include "imgui.h"
#include "imgui_impl_metal.h"
#ifdef TARGET_MACOS
#include "imgui_impl_osx.h"
#endif

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

#include <iostream>

#include <fstream>

void Editor::StartUp(MTKView* view, id<MTLDevice> device)
{
    // Setup Dear ImGui context
    // FIXME: This example doesn't have proper cleanup...
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    // Setup Renderer backend
    ImGui_ImplMetal_Init(device);

#if TARGET_MACOS
    ImGui_ImplOSX_Init(view);
    [NSApp activateIgnoringOtherApps:YES];
#endif

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.txt' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);
}

void Editor::BeginFrame(MTKView* view, MTLRenderPassDescriptor* currentRenderPassDescriptor)
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

#if TARGET_MACOS
    CGFloat framebufferScale = view.window.screen.backingScaleFactor ?: NSScreen.mainScreen.backingScaleFactor;
#else
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
#endif
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);


    // Start the Dear ImGui frame
    ImGui_ImplMetal_NewFrame(currentRenderPassDescriptor);
#if TARGET_MACOS
    ImGui_ImplOSX_NewFrame(view);
#endif
    ImGui::NewFrame();
}

namespace
{
    void EntityEditor(std::map<ID, Entity>& entities)
    {
        for (auto& [ID, e] : entities) {
            ImGui::PushID(int(ID));
            ImGui::Text("%s", std::to_string(ID).data());

            ImGui::Text("Transforms");
            {
                auto& transform = e.rootTransform;

                ImGui::SliderFloat3("pos", transform.position.data(), -10.0f, 10.0f);
                ImGui::SliderFloat3("rotation", transform.rotation.data(), -10.0f, 10.0f);

                float scale = transform.scale.x();
                ImGui::SliderFloat("scale", &scale, 0.f, 10.f);
                transform.scale = {scale, scale, scale};
            }

            ImGui::Text("Material");
            {
                auto& material = e.meshes[0].material;
                ImGui::ColorEdit3("diffuse", material.diffuse.data());
                ImGui::ColorEdit3("specular", material.specular.data());
            }

            ImGui::PopID();
        }
    }

    rapidjson::Value SerializeVector3(const Math::Vector3& v, rapidjson::MemoryPoolAllocator<>& allocator) {
        rapidjson::Value value(rapidjson::kArrayType);
        value.Reserve(3, allocator);
        value.PushBack(v.x(), allocator);
        value.PushBack(v.y(), allocator);
        value.PushBack(v.z(), allocator);
        return value;
    }

    Math::Vector3 DeserializeVector3(const rapidjson::Value& value) {
        assert(value.IsArray() || value.Size() == 3);

        Math::Vector3 vector;
        vector[0] = value[0].GetFloat();
        vector[1] = value[1].GetFloat();
        vector[2] = value[2].GetFloat();

        return vector;
    }
}

void Editor::SceneSerialization(World& world)
{

    static char str0[1024] = "/Users/marcisolti/git/ifem-metal/Assets/scene.json";
    ImGui::InputText("sceneToSave", str0, IM_ARRAYSIZE(str0));
    ImGui::SameLine();
    if (ImGui::Button("Save scene"))
        SaveScene(str0, world);

    static char str1[1024] = "/Users/marcisolti/git/ifem-metal/Assets/scene.json";
    ImGui::InputText("sceneToLoad", str1, IM_ARRAYSIZE(str1));
    ImGui::SameLine();
    if (ImGui::Button("Load scene"))
        LoadScene(str1, world);

}

void Editor::SaveScene(const std::string& path, const World& world)
{
    // /Users/marcisolti/git/filament/out/cmake-release/samples/assets/models/monkey/monkey.obj

    using namespace rapidjson;
    Document document(kObjectType);
    {
        MemoryPoolAllocator<> allocator;

        // Entities
        {
            Value entities(kArrayType);
            entities.Reserve(SizeType(world.scene.entities.size()), allocator);
            for (const auto& [Id, entity] : world.scene.entities)
            {
                Value meshes(kArrayType);
                meshes.Reserve(SizeType(entity.meshes.size()), allocator);
                for (const auto& mesh : entity.meshes)
                {
                    Value meshData(kObjectType);
                    meshData.AddMember("id", mesh.mesh, allocator);
                    meshData.AddMember("material",
                                       Value(kObjectType)
                                       .AddMember("ambient",  SerializeVector3(mesh.material.ambient, allocator), allocator)
                                       .AddMember("diffuse",  SerializeVector3(mesh.material.diffuse, allocator), allocator)
                                       .AddMember("specular", SerializeVector3(mesh.material.specular, allocator), allocator),
                                       allocator);
                    meshes.PushBack(meshData, allocator);
                }
                Value rootTransform(kObjectType);
                rootTransform
                    .AddMember("position", SerializeVector3(entity.rootTransform.position, allocator), allocator)
                    .AddMember("rotation", SerializeVector3(entity.rootTransform.rotation, allocator), allocator)
                    .AddMember("scale", SerializeVector3(entity.rootTransform.scale, allocator), allocator);

                entities.PushBack(Value(kObjectType)
                                  .AddMember("id", Id, allocator)
                                  .AddMember("rootTransform", rootTransform, allocator)
                                  .AddMember("meshes", meshes, allocator),
                                  allocator);

            }
            document.AddMember("entities", entities, allocator);
        }

        // Meshes
        {
            Value meshes(kArrayType);
            meshes.Reserve(SizeType(assetPaths.size()), allocator);
            for (const auto& [Id, path] : assetPaths)
            {
                Value meshData(kObjectType);
                meshData.AddMember("id", Id, allocator);
                meshData.AddMember("path", Value().SetString(path.c_str(), SizeType(path.size())), allocator);
                meshes.PushBack(meshData, allocator);
            }
            document.AddMember("meshes", meshes, allocator);
        }

    }

    // Write file
    {
        StringBuffer buffer;
        Writer<StringBuffer> writer(buffer);
        document.Accept(writer);

        std::ofstream file;
        file.open(path);
        file << buffer.GetString();
        file.close();
    }
}

void Editor::LoadScene(const std::string& path, World& world)
{
    using namespace rapidjson;
    Document d;
    {
        std::ifstream file;
        std::string content;

        file.open(path);
        file >> content;
        file.close();

        d.Parse(content.c_str());
    }


    /*
     {
         "entities": [
             {
                 "id": 1,
                 "meshes": [
                     {
                         "id": 0,
                         "material": {
                             "ambient": [
                                 1.0,
                                 1.0,
                                 1.0
                             ],
                             "diffuse": [
                                 1.0,
                                 1.0,
                                 1.0
                             ],
                             "specular": [
                                 1.0,
                                 1.0,
                                 1.0
                             ]
                         }
                     }
                 ]
             }
         ],
         "meshes": [
             {
                 "id": 0,
                 "path": "/Users/marcisolti/git/filament/out/cmake-release/samples/assets/models/monkey/monkey.obj"
             }
         ]
     }
     */

    // <Parsed ID, Run-time ID>
    std::map<ID, ID> meshMap;
    std::map<ID, ID> entityMap;

    world.scene.entities.clear();

    const Value& meshArray = d["meshes"];
    const Value& entities = d["entities"];
    for (const auto& mesh : meshArray.GetArray())
    {
        ID runTimeID = GetID();
        const auto& path = mesh["path"].GetString();
        world.meshesToLoad.push_back({runTimeID, path});
        assetPaths.insert({runTimeID, path});
        meshMap.insert({mesh["id"].GetInt(), runTimeID});
    }

    for (const auto& entity : entities.GetArray())
    {
        const Value& mesh = entity["meshes"].GetArray()[0];
        const Value& material = mesh["material"];

        Material mat = {
            DeserializeVector3(material["ambient"]),
            DeserializeVector3(material["diffuse"]),
            DeserializeVector3(material["specular"])
        };
        ShadedMesh shaded = {
            meshMap.at(mesh["id"].GetInt()),
            mat,
            {} // transform
        };
        ID runTimeEntityID = GetID();

        const Value& rootTransform = entity["rootTransform"];
        Transform t = {
            DeserializeVector3(rootTransform["position"]),
            DeserializeVector3(rootTransform["rotation"]),
            DeserializeVector3(rootTransform["scale"])
        };
        world.scene.entities.insert({runTimeEntityID, Entity({shaded}, t)});
        entityMap.insert({entity["id"].GetInt(), runTimeEntityID});
    }

}



void Editor::AddEntity(std::map<ID, Entity>& entities, std::vector<MeshToLoad>& meshesToLoad)
{
    static char str0[1024] = "Entes asset path here";
    ImGui::InputText("Input", str0, IM_ARRAYSIZE(str0));
    ImGui::SameLine();
    if(ImGui::Button("Add Entity"))
    {
        const ID meshID = GetID();
        meshesToLoad.push_back({meshID, str0});
        assetPaths.insert({meshID, str0});

        ShadedMesh s {
            .mesh = meshID,
        };
        const Entity e({s});
        entities.insert({GetID(), e});

    }
}


void Editor::Update(World& world)
{
    static bool show_demo_window = true;
    if (show_demo_window) ImGui::ShowDemoWindow(&show_demo_window);

    {
        ImGui::Begin("World Editor");

        SceneSerialization(world);

        // Manipulate entities
        AddEntity(world.scene.entities, world.meshesToLoad);
        EntityEditor(world.scene.entities);

        ImGui::ColorEdit3("clear color", (float*)&world.config.clearColor);

        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        ImGui::Checkbox("Demo Window", &show_demo_window);

        ImGui::End();
    }
}

void Editor::Draw(id<MTLRenderCommandEncoder> renderEncoder, id<MTLCommandBuffer> commandBuffer)
{
    // Rendering
    ImGui::Render();
    ImDrawData* draw_data = ImGui::GetDrawData();

    [renderEncoder pushDebugGroup:@"Dear ImGui rendering"];
    ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
    [renderEncoder popDebugGroup];
}
