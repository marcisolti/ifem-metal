//
//  MetalKitView.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "MetalKitView.h"

#import "Renderer.h"
#import "Editor.h"

@implementation MetalKitView
{
    Renderer g_Renderer;
    Editor g_Editor;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        g_Renderer.StartUp(mtkView);
        g_Editor.StartUp(mtkView, g_Renderer.GetDevice());
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
    g_Editor.Draw(view, g_Renderer.GetCurrentPassDescriptor(), g_Renderer.GetRenderEncoder(), g_Renderer.GetCommandBuffer());

    g_Renderer.EndFrame();
    
}

@end
