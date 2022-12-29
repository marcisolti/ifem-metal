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
#include <filesystem>

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
    rapidjson::Value SerializeVector3(const Math::Vector3& v, rapidjson::MemoryPoolAllocator<>& allocator)
    {
        rapidjson::Value value(rapidjson::kArrayType);
        value.Reserve(3, allocator);
        value.PushBack(v.x(), allocator);
        value.PushBack(v.y(), allocator);
        value.PushBack(v.z(), allocator);
        return value;
    }

    Math::Vector3 DeserializeVector3(const rapidjson::Value& value)
    {
        assert(value.IsArray() || value.Size() == 3);

        Math::Vector3 vector;
        vector[0] = value[0].GetFloat();
        vector[1] = value[1].GetFloat();
        vector[2] = value[2].GetFloat();

        return vector;
    }

    rapidjson::Value SerializeTransform(const Transform& t, rapidjson::MemoryPoolAllocator<>& allocator)
    {
        rapidjson::Value ret(rapidjson::kObjectType);
        ret.AddMember("position", SerializeVector3(t.position, allocator), allocator)
           .AddMember("rotation", SerializeVector3(t.rotation, allocator), allocator)
           .AddMember("scale", SerializeVector3(t.scale, allocator), allocator);
        return ret;
    }

    Transform DeserializeTransform(const rapidjson::Value& t)
    {
        return {
            DeserializeVector3(t["position"]),
            DeserializeVector3(t["rotation"]),
            DeserializeVector3(t["scale"])
        };
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
    if (ImGui::Button("Load scene")) {
        LoadScene(str1, world);
        world.config.rebuildPhysics = true;
    }

}

void Editor::SaveScene(const std::string& path, const World& world)
{
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

                Value shadedMeshObject(kObjectType);
                {
                    const auto& shadedMesh = entity.shadedMesh;
                    const auto& material = shadedMesh.material;
                    shadedMeshObject.AddMember("id", shadedMesh.mesh, allocator);
                    shadedMeshObject.AddMember("material",
                                               Value(kObjectType)
                                               .AddMember("baseColor",  SerializeVector3(material.baseColor, allocator), allocator)
                                               .AddMember("smoothness",  material.smoothness, allocator)
                                               .AddMember("f0",  material.f0, allocator)
                                               .AddMember("f90",  material.f90, allocator)
                                               .AddMember("isMetal",  material.isMetal, allocator),
                                               allocator);
                }

                Value physicsObject(kObjectType);
                {
                    const auto& component = entity.physicsComponent;

                    {
                        std::string shapeString;
                        switch (component.shape) {
                            case ::Sphere: {
                                shapeString = "sphere";
                            } break;
                            case ::Box: {
                                shapeString = "box";
                            } break;
                        }
                        Value shapeStringObject(kStringType);
                        shapeStringObject.SetString(shapeString.c_str(), SizeType(shapeString.size()), allocator);
                        physicsObject.AddMember("shape", shapeStringObject, allocator);
                    }

                    {
                        std::string typeString;
                        switch (component.type) {
                            case ::Static: {
                                typeString = "static";
                            } break;
                            case ::Dynamic: {
                                typeString = "dynamic";
                            } break;
                        }
                        Value typeStringObject(kStringType);
                        typeStringObject.SetString(typeString.c_str(), SizeType(typeString.size()), allocator);
                        physicsObject.AddMember("type", typeStringObject, allocator);
                    }
                }

                entities.PushBack(Value(kObjectType)
                                    .AddMember("id", Id, allocator)
                                    .AddMember("rootTransform", SerializeTransform(entity.rootTransform, allocator), allocator)
                                    .AddMember("shadedMesh", shadedMeshObject, allocator)
                                    .AddMember("physicsComponent", physicsObject, allocator),
                                  allocator);
            }
            document.AddMember("entities", entities, allocator);
        }

        // Lights
        {
            Value lights(kArrayType);
            lights.Reserve(SizeType(world.scene.lights.size()), allocator);

            for (const auto& [Id, light] : world.scene.lights)
            {
                lights.PushBack(Value(kObjectType)
                                    .AddMember("id", Id, allocator)
                                    .AddMember("position", SerializeVector3(light.position, allocator), allocator)
                                    .AddMember("intensity", light.intensity, allocator)
                                    .AddMember("color", SerializeVector3(light.color, allocator), allocator),
                                  allocator);
            }
            document.AddMember("lights", lights, allocator);
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

        // Config
        {
            Value config(kObjectType);
            config.AddMember("clearColor", SerializeVector3(world.config.clearColor, allocator), allocator);
            document.AddMember("config", config, allocator);
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
        std::string content;
        {
            std::ifstream file;

            file.open(path);
            std::string line;
            while (std::getline(file, line))
                content += line;
            file.close();
        }

        d.Parse(content.c_str());
    }

    world.scene.entities.clear();
    world.scene.lights.clear();
    assetPaths.clear();

    // <Parsed ID, Run-time ID>
    std::map<ID, ID> meshMap;
    std::map<ID, ID> entityMap;

    const Value& meshArray = d["meshes"];
    for (const auto& mesh : meshArray.GetArray())
    {
        ID runTimeID = GetID();
        const auto& path = mesh["path"].GetString();
        world.meshesToLoad.push_back({runTimeID, path});
        assetPaths.insert({runTimeID, path});
        meshMap.insert({mesh["id"].GetInt(), runTimeID});
    }

    const Value& entities = d["entities"];
    for (const auto& entity : entities.GetArray())
    {
        const Value& mesh = entity["shadedMesh"];
        const Value& material = mesh["material"];

        Material mat = {
            DeserializeVector3(material["baseColor"]),
            material["smoothness"].GetFloat(),
            material["f0"].GetFloat(),
            material["f90"].GetFloat(),
            material["isMetal"].GetBool(),
        };
        ShadedMesh shaded = {
            meshMap.at(mesh["id"].GetInt()),
            mat
        };

        const Value& component = entity["physicsComponent"];

        PhysicsShape shape;
        {
            std::string shapeString = component["shape"].GetString();
            if (shapeString == "sphere") {
                shape = ::Sphere;
            } else if (shapeString == "box") {
                shape = ::Box;
            } else {
                assert(false);
            }
        }

        PhysicsType type;
        {
            std::string typeString = component["type"].GetString();
            if (typeString == "static") {
                type = ::Static;
            } else if (typeString == "dynamic") {
                type = ::Dynamic;
            } else {
                assert(false);
            }
        }

        Entity e(shaded,
                 DeserializeTransform(entity["rootTransform"]),
                 {.shape = shape, .type = type, {}});

        ID runTimeEntityID = GetID();
        world.scene.entities.insert({runTimeEntityID, e});
        entityMap.insert({entity["id"].GetInt(), runTimeEntityID});

    }

    const Value& lights = d["lights"];
    for (const auto& light : lights.GetArray())
    {
        const Light l = {
            .position = DeserializeVector3(light["position"]),
            .color = DeserializeVector3(light["color"]),
            .intensity = light["intensity"].GetFloat()
        };
        world.scene.lights.insert({GetID(), l});
    }

    const Value& config = d["config"];
    {
        world.config.clearColor = DeserializeVector3(config["clearColor"]);
    }
}

void Editor::EntityEditor(std::map<ID, Entity>& entities)
{
    for (auto& [ID, e] : entities) {
        ImGui::PushID(int(ID));
        std::string idText = std::to_string(ID);
        if (ImGui::TreeNode(idText.data())) {
            ImGui::Text("Transforms");
            {
                auto& transform = e.rootTransform;

                ImGui::SliderFloat3("pos", transform.position.data(), -10.0f, 10.0f);
                ImGui::SliderFloat3("rotation", transform.rotation.data(), -10.0f, 10.0f);

                float scale = transform.scale.x();
                ImGui::SliderFloat("scale", &scale, 0.f, 10.f);
                transform.scale = {scale, scale, scale};
            }

            ImGui::Text("Mesh geometry");
            {
                std::string accumulated;
                std::map<uint32_t, int> meshIndicesInList; // putting ID instead uint32_t does not compile??????

                int index = 0;
                for (const auto& [meshID, path] : assetPaths) {
                    accumulated += std::filesystem::path(path).filename();
                    accumulated += '\0';

                    meshIndicesInList.insert({meshID, index++}); // do we really need this ??
                }

                int currentIndex = meshIndicesInList[e.shadedMesh.mesh];
                ImGui::Combo("combo 2 (one-liner)", &currentIndex, accumulated.data());

                auto it = meshIndicesInList.begin();
                for(int i = 0; i < currentIndex; i++)
                    it++;
                e.shadedMesh.mesh = it->first;
            }

            ImGui::Text("Material");
            {
                auto& material = e.shadedMesh.material;
                ImGui::ColorEdit3("diffuse", material.baseColor.data());
                ImGui::SliderFloat("smoothness", &material.smoothness, 0.f, 1.f);
                ImGui::SliderFloat("f0", &material.f0, 0.f, 1.f);
                ImGui::SliderFloat("f90", &material.f90, 0.f, 1.f);
            }

            ImGui::Text("Physics");
            {
                auto& component = e.physicsComponent;

                PhysicsShape shapes[] = {::Sphere, ::Box};
                int shapeIndex = int(component.shape);
                ImGui::Combo("shape", &shapeIndex, "sphere\0box\0\0", 2);
                component.shape = shapes[shapeIndex];

                PhysicsType types[] = {::Static, ::Dynamic};
                int typeIndex = int(component.type);
                ImGui::Combo("type", &typeIndex, "static\0dynamic\0\0", 2);
                component.type = types[typeIndex];
            }

            ImGui::TreePop();
        }
        ImGui::PopID();
    }
}

void Editor::LightEditor(std::map<ID, Light>& lights)
{
    for (auto& [ID, l] : lights) {
        ImGui::PushID(int(ID));
        std::string idText = std::to_string(ID);
        if (ImGui::TreeNode(idText.data())) {
            ImGui::SliderFloat3("position", l.position.data(), -10.f, 10.f);
            ImGui::SliderFloat("intensity", &l.intensity, 0.f, 20.f);
            ImGui::ColorEdit3("color", l.color.data());

            ImGui::TreePop();
        }
        ImGui::PopID();
    }
}

void Editor::AddMesh(std::vector<MeshToLoad>& meshesToLoad)
{
    static char str0[1024] = "Entes asset path here";
    ImGui::InputText("Input", str0, IM_ARRAYSIZE(str0));
    ImGui::SameLine();
    if(ImGui::Button("Add Mesh Geometry"))
    {
        const ID meshID = GetID();
        meshesToLoad.push_back({meshID, str0});
        assetPaths.insert({meshID, str0});
    }
}

void Editor::Update(World& world)
{
    static bool show_demo_window = false;
    if (show_demo_window) ImGui::ShowDemoWindow(&show_demo_window);

    ImGui::Begin("World Editor");
    {

        if (ImGui::CollapsingHeader("Add Assets"))
        {
            SceneSerialization(world);
            AddMesh(world.meshesToLoad);
        }

        if (ImGui::CollapsingHeader("Entities"))
        {
            auto& entities = world.scene.entities;
            if (ImGui::Button("Add Entity"))
            {
                ShadedMesh s {
                    .mesh = (*assetPaths.begin()).first,
                };
                const Entity e(s);
                entities.insert({GetID(), e});
            }

            EntityEditor(entities);
        }

        if (ImGui::CollapsingHeader("Lights"))
        {
            auto& lights = world.scene.lights;
            if (ImGui::Button("Add Light"))
            {
                const Light l {
                    .position = { 0.f, 0.f, 0.f },
                    .color = { 1.f, 1.f, 1.f },
                    .intensity = 10.f
                };
                lights.insert({GetID(), l});
            }

            LightEditor(lights);
        }

        if (ImGui::CollapsingHeader("Config"))
        {
            auto& config = world.config;
            ImGui::ColorEdit3("clear color", config.clearColor.data());
            ImGui::Checkbox("trackpad panning", &config.isTrackpadPanning);
            if (ImGui::Button("rebuild physics"))
                config.rebuildPhysics = true;
        }

        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        ImGui::Checkbox("Demo Window", &show_demo_window);

    }
    ImGui::End();
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
