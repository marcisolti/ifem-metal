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

#include "Renderer/Renderer.h"
#include "Simulator/Simulator.h"
#include "State.h"

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
        NSString* bundlePath = [[NSBundle mainBundle] resourcePath];

        Config currentConfig {
            .bundlePath { [bundlePath UTF8String] },
            .simulator {
                .modelName { "turtle" },
                .h = 0.005,
                .magicConstant = 1.e-5,
                .maxCGIteration = 150,

                .loadStep = -100000.0,
                .loadedVert = 296,
                .BCs = { 1, 3, 6, 8, 11, 12, 13, 15, 17, 18, 26, 29, 42, 45, 47, 49, 58, 59, 60, 247, 248, 256, 265 },

                .material {
                    .E = 30,
                    .nu = 0.35,
                    .rho = 1000,
                }
            }
        };

        g_Simulator.StartUp(currentConfig);
        g_Renderer.StartUp(mtkView, currentConfig);
    }

    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    auto start = std::chrono::steady_clock::now();

    const State currentState = { g_Renderer.GetSelectedVert() }; // get it from app
    const Result& result = g_Simulator.Step(currentState);
    g_Renderer.Draw(view, currentState, result);

    auto end = std::chrono::steady_clock::now();
    std::cout << "f: " << std::chrono::duration_cast<std::chrono::microseconds>(end-start).count() << " µs\n";

}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    g_Renderer.SetViewportSize(size);
}

- (void) touchesBeganAt:(CGPoint)touchPos
{
    g_Renderer.SetReadPos(touchPos);
}

@end
