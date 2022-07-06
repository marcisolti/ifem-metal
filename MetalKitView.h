//
//  MetalKitView.mm
//  iFEM
//
//  Created by Marci Solti on 2022. 05. 21..
//  Copyright © 2022. Apple. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MetalKitView : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (void) touchesBeganAt:(CGPoint)touchPos;

@end
