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
    }

    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    g_Renderer.SetViewportSize(size);
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    g_Renderer.Draw(view);
}

@end
