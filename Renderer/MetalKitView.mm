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
#include "../Simulator/Simulator.h"
#include "../Simulator/Config.h"

#include <chrono>
#include <iostream>

@implementation MetalKitView
{
    Renderer g_Renderer;
    Simulator g_Simulator;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        Config config {
            .simulator = {
                .modelName = "suz"
            }
        };

        g_Simulator.StartUp(config);
        g_Renderer.StartUp(mtkView, config);
    }

    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    auto start = std::chrono::steady_clock::now();

    const State currentState = {}; // get it from app
    const Result& result = g_Simulator.Step(currentState);
    g_Renderer.Draw(view, currentState, result);

    auto end = std::chrono::steady_clock::now();
    std::cout << "frame time: " << std::chrono::duration_cast<std::chrono::microseconds>(end-start).count() << " µs\n";
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    g_Renderer.SetViewportSize(size);
}

@end
