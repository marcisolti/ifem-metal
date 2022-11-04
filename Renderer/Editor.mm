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
            ImGui::SliderFloat3("pos", (float*)&e.transform.position, -10.0f, 10.0f);
            ImGui::PopID();
        }
    }

    void AddEntity(std::map<ID, Entity>& entities)
    {
        if(ImGui::Button("Add Entity"))
        {
            ShadedMesh s {
                .mesh = 0,
                .material = {{1,1,1}, {1,1,1}, {1,1,1}}
            };
            Entity e({s});
            entities.insert({GetID(), e});
        }
    }
}

void Editor::Update(World& world)
{
    static bool show_demo_window = true;
    if (show_demo_window) ImGui::ShowDemoWindow(&show_demo_window);

    {
        ImGui::Begin("World Editor");

        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);

        AddEntity(world.scene.entities);
        
        EntityEditor(world.scene.entities);

        ImGui::ColorEdit3("clear color", (float*)&world.config.clearColor);

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
