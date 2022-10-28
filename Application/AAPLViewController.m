/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of our cross-platform view controller
*/


#import "AAPLViewController.h"
#import "MetalKitView.h"
#include <stdio.h>
@implementation AAPLViewController
{
    MTKView *_view;

    MetalKitView *_renderer;
//    NSPanGestureRecognizer* rec;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;
//    rec = [[NSPanGestureRecognizer alloc] ini
//    [_view  addGestureRecognizer:<#(nonnull NSGestureRecognizer *)#>]

    _view.device = MTLCreateSystemDefaultDevice();
    NSAssert(_view.device, @"Metal is not supported on this device");
    
    _renderer = [[MetalKitView alloc] initWithMetalKitView:_view];
        NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;
}

-(void)mouseDragged:(NSEvent *)event
{
    [_renderer mouseDragged:CGPointMake(event.deltaX, event.deltaY)];
}

- (void)keyDown:(NSEvent *)theEvent {

    if ([theEvent modifierFlags]) { // arrow keys have this mask
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ( [theArrow length] == 0 )
            return;            // reject dead keys
        if ( [theArrow length] == 1 ) {
            keyChar = [theArrow characterAtIndex:0];
            if ( keyChar == NSLeftArrowFunctionKey ) {
//                [self offsetLocationByX:-10.0 andY:0.0];
//                [[self window] invalidateCursorRectsForView:self];
                return;
            }
            if ( keyChar == NSRightArrowFunctionKey ) {
//                [self offsetLocationByX:10.0 andY:0.0];
//                [[self window] invalidateCursorRectsForView:self];
                return;
            }
            if ( keyChar == NSUpArrowFunctionKey ) {
//                [self offsetLocationByX:0 andY: 10.0];
//                [[self window] invalidateCursorRectsForView:self];
                return;
            }
            if ( keyChar == 'w' || keyChar == 'W') {
                [_renderer keyPressed:0];
                return;
            }
            if ( keyChar == 'a' || keyChar == 'A') {
                [_renderer keyPressed:1];
                return;
            }
            if ( keyChar == 's' || keyChar == 'S') {
                [_renderer keyPressed:2];
                return;
            }
            if ( keyChar == 'd' || keyChar == 'D') {
                [_renderer keyPressed:3];
                return;
            }
            [super keyDown:theEvent];
        }
    }
    [super keyDown:theEvent];
}

@end
