//
//  MetalKitView.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include "imgui.h"
#include "imgui_impl_metal.h"
#ifdef TARGET_MACOS
#include "imgui_impl_osx.h"
#endif

#import "MetalKitView.h"

#import "Renderer.h"

@implementation MetalKitView
{
    Renderer g_Renderer;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        g_Renderer.StartUp(mtkView);

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
        ImGui_ImplMetal_Init(mtkView.device);

#if TARGET_MACOS
        ImGui_ImplOSX_Init(mtkView);
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

    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    g_Renderer.SetViewportSize(size);
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    g_Renderer.BeginFrame(view);

    g_Renderer.Draw();

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

        //    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        //
        //    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        //    if (renderPassDescriptor == nil)
        //    {
        //        [commandBuffer commit];
        //        return;
        //    }

        // Start the Dear ImGui frame
        ImGui_ImplMetal_NewFrame(view.currentRenderPassDescriptor);
#if TARGET_MACOS
        ImGui_ImplOSX_NewFrame(view);
#endif
        ImGui::NewFrame();

        // Our state (make them static = more or less global) as a convenience to keep the example terse.
        static bool show_demo_window = true;
        static bool show_another_window = false;
        static ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

        // 1. Show the big demo window (Most of the sample code is in ImGui::ShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
        if (show_demo_window)
            ImGui::ShowDemoWindow(&show_demo_window);

        // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
        {
            static float f = 0.0f;
            static int counter = 0;

            ImGui::Begin("Hello, world!");                          // Create a window called "Hello, world!" and append into it.

            ImGui::Text("This is some useful text.");               // Display some text (you can use a format strings too)
            ImGui::Checkbox("Demo Window", &show_demo_window);      // Edit bools storing our window open/close state
            ImGui::Checkbox("Another Window", &show_another_window);

            ImGui::SliderFloat("float", &f, 0.0f, 1.0f);            // Edit 1 float using a slider from 0.0f to 1.0f
            ImGui::ColorEdit3("clear color", (float*)&clear_color); // Edit 3 floats representing a color

            if (ImGui::Button("Button"))                            // Buttons return true when clicked (most widgets return true when edited/activated)
                counter++;
            ImGui::SameLine();
            ImGui::Text("counter = %d", counter);

            ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
            ImGui::End();
        }

        // 3. Show another simple window.
        if (show_another_window)
        {
            ImGui::Begin("Another Window", &show_another_window);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
            ImGui::Text("Hello from another window!");
            if (ImGui::Button("Close Me"))
                show_another_window = false;
            ImGui::End();
        }

        // Rendering
        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();

        //    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);

            id <MTLRenderCommandEncoder> renderEncoder = g_Renderer.GetRenderEncoder();
            [renderEncoder pushDebugGroup:@"Dear ImGui rendering"];
            ImGui_ImplMetal_RenderDrawData(draw_data, g_Renderer.GetCommandBuffer(), renderEncoder);
            [renderEncoder popDebugGroup];
//            [renderEncoder endEncoding];
        //
        //    // Present
        //    [commandBuffer presentDrawable:view.currentDrawable];
        //    [commandBuffer commit];

    }
    g_Renderer.EndFrame();
    
}

@end
