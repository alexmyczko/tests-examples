/* Image-test.m: test that fills/strokes line up on the desired
   pixel boundaries.

   Copyright (C) 2011 Free Software Foundation, Inc.

   Author:  Eric Wasylishen <ewasylishen@gmail.com>
   Date: 2011
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "../GSTestProtocol.h"

static NSImage *ImageFromBundle(NSString *name, NSString *type);

static void AddLabel(NSString *text, NSRect frame, NSView *dest)
{
  NSTextField *labelView = [[NSTextField alloc] initWithFrame: frame];
  [labelView setStringValue: text];
  [labelView setEditable: NO];
  [labelView setSelectable: NO];
  [labelView setBezeled: NO];
  [labelView setFont: [NSFont labelFontOfSize: 10]];
  [labelView setDrawsBackground: NO];
  [dest addSubview: labelView];
  [labelView release];
}

@interface ImageTest : NSObject <GSTest>
{
  NSWindow *win;
}
-(void) restart;
@end

@interface VectorTestRep : NSImageRep
{
}

+ (NSImage*) testImage;

@end

@interface FlippedTestView : NSView
{
  NSImage *gsImage;
}
@end

@implementation FlippedTestView

- (id)initWithFrame: (NSRect)aFrame
{
  self = [super initWithFrame: aFrame];
  if (self)
    {
      AddLabel(@"(10, 10) This is a flipped view", NSMakeRect(10,10,300,12), self);
      AddLabel(@"Composite image to (10, 80):", NSMakeRect(10,30,300,12), self);
      AddLabel(@"Draw image at (10, 100) (should be up-side down):", NSMakeRect(10,85,300,12), self);
      AddLabel(@"Draw image at (10, 155) using respectFlipped: YES:", NSMakeRect(10,140,300,12), self);
      gsImage = [ImageFromBundle(@"gs", @"png") retain];
    }
  return self;
}

- (void)dealloc
{
  [gsImage release];
  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

- (void) drawRect: (NSRect)dirty
{
  NSDrawDarkBezel([self bounds], dirty);

  [gsImage compositeToPoint: NSMakePoint(10,80)
		   fromRect: NSZeroRect
		  operation: NSCompositeSourceOver
		   fraction: 1.0];

  [gsImage drawAtPoint: NSMakePoint(10,100)
	      fromRect: NSZeroRect
	     operation: NSCompositeSourceOver
	      fraction: 1.0];

  [gsImage drawInRect: NSMakeRect(10,155, [gsImage size].width, [gsImage size].height)
	     fromRect: NSZeroRect
	    operation: NSCompositeSourceOver
	     fraction: 1.0
       respectFlipped: YES
		hints: nil];
}

@end


@interface ImageTestView : NSView
{
}

@end

@implementation ImageTestView

static NSImage *ImageFromBundle(NSString *name, NSString *type)
{
  return [[[NSImage alloc] initWithContentsOfFile:
			[[NSBundle bundleForClass: [ImageTestView class]] pathForResource: name ofType: type]] autorelease];
}

- (id)initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  
  if (self != nil)
    {
      NSView *flipped = [[FlippedTestView alloc] initWithFrame: NSMakeRect(10, 200, 260, 200)];
      [self addSubview: flipped];
      [flipped release];
    }
  return self;
}

- (void) drawRect: (NSRect)dirty
{
  // Test drawing with a complex clip path
  {
    NSImage *img = ImageFromBundle(@"plasma", @"png");

    [[NSGraphicsContext currentContext] saveGraphicsState];

    // Set the clipping path to a 'g' character
    {
      NSFont *font = [NSFont fontWithName: @"Helvetica" size: 64.0];
      NSBezierPath *clip = [NSBezierPath bezierPath];
      [clip moveToPoint: NSMakePoint(68,68)];
      [clip appendBezierPathWithGlyph: [font glyphWithName: @"a"]
			       inFont: font];
      [clip addClip];
    }

    [img drawInRect: NSMakeRect(64,64,128,128)
	   fromRect: NSZeroRect
	  operation: NSCompositeSourceOver
	  fraction: 1.0];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }

  // Test drawing sub-regions of an image
  {
    NSImage *img = ImageFromBundle(@"fourcorners", @"png");

    [img drawInRect: NSMakeRect(128,64,32,32)
	   fromRect: NSMakeRect(0,64,64,64)
	  operation: NSCompositeSourceOver
	  fraction: 1.0];

    [img drawAtPoint: NSMakePoint(192, 64)
	    fromRect: NSMakeRect(0,64,64,64)
	   operation: NSCompositeSourceOver
	    fraction: 1.0];

    [img compositeToPoint: NSMakePoint(128, 128)
		 fromRect: NSMakeRect(64,64,64,64)
		operation: NSCompositeSourceOver];
  }

  // Test that drawing a vector rep scales properly
  {
    NSImage *img = [VectorTestRep testImage];
    
    [img drawAtPoint: NSMakePoint(256, 0)
	   fromRect: NSZeroRect
	  operation: NSCompositeSourceOver
	  fraction: 1.0];

    [img drawInRect: NSMakeRect(300, 0, 100, 100)
	   fromRect: NSZeroRect
	  operation: NSCompositeSourceOver
	   fraction: 1.0];
  }

  // Test drawing into an NSBitmapImageRep
  {
    NSImage *img;
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
								    pixelsWide: 64
								    pixelsHigh: 64
								 bitsPerSample: 8
							       samplesPerPixel: 4
								      hasAlpha: YES
								      isPlanar: NO
								colorSpaceName: NSCalibratedRGBColorSpace
								  bitmapFormat: 0
								   bytesPerRow: 0
								  bitsPerPixel: 0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:
			 [NSGraphicsContext graphicsContextWithBitmapImageRep: rep]];
    [[NSColor purpleColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0,0,64,64)] fill];
    [NSGraphicsContext restoreGraphicsState];
    
    
    img = [[[NSImage alloc] initWithSize: NSMakeSize(64,64)] autorelease];
    [img addRepresentation: rep];
    
    [img drawInRect: NSMakeRect(400, 0,64,64)
	   fromRect: NSZeroRect
	  operation: NSCompositeSourceOver
	   fraction: 0.5];
    
    [img drawInRect: NSMakeRect(432, 0,64,64)
	   fromRect: NSZeroRect
	  operation: NSCompositeSourceOver
	   fraction: 0.5];

    // Stroke around where the images should be drawn

    [[NSColor purpleColor] setStroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(400,0,64,64)] stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(432,0,64,64)] stroke];
  }
}
@end

@implementation ImageTest : NSObject

-(id) init
{
  NSView *content;
  content = [[ImageTestView alloc] initWithFrame: NSMakeRect(0,0,800,445)];

  // Create the window
  win = [[NSWindow alloc] initWithContentRect: [content frame]
			  styleMask: (NSTitledWindowMask 
				      | NSClosableWindowMask 
				      | NSMiniaturizableWindowMask 
				      | NSResizableWindowMask)
			  backing: NSBackingStoreBuffered
			  defer: NO];
  [win setReleasedWhenClosed: NO];
  [win setContentView: content];
  [win setMinSize: [win frame].size];
  [win setTitle: @"Image Test"];
  [self restart];
  return self;
}

-(void) restart
{
  [win orderFront: nil]; 
  [[NSApplication sharedApplication] addWindowsItem: win
				     title: [win title]
				     filename: NO];
}

- (void) dealloc
{
  RELEASE (win);
  [super dealloc];
}

@end

@implementation VectorTestRep

- (id)init
{
  [self setSize: NSMakeSize(32, 32)];
  [self setAlpha: YES];
  [self setOpaque: NO];
  [self setBitsPerSample: NSImageRepMatchesDevice];
  [self setPixelsWide: NSImageRepMatchesDevice];
  [self setPixelsHigh: NSImageRepMatchesDevice];
  return self;
}

- (BOOL)draw
{
  [[[NSColor blueColor] colorWithAlphaComponent: 0.5] set];
  [NSBezierPath setDefaultLineWidth: 2.0];
  [NSBezierPath strokeRect: NSMakeRect(1, 1, 28, 28)];
  
  [[[NSColor redColor] colorWithAlphaComponent: 0.5] set];
  [NSBezierPath setDefaultLineWidth: 1.0];
  [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(2,2,26,26)] stroke];
  
  [@"Vector Rep" drawInRect: NSMakeRect(2,2,26,26)
	     withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSFont userFontOfSize: 8], NSFontAttributeName,
					   nil]];
  
  return YES;
}

+ (NSImage *)testImage
{
  NSImage *img = [[[NSImage alloc] initWithSize: NSMakeSize(32, 32)] autorelease];
  [img addRepresentation: [[[self alloc] init] autorelease]];
  return img;
}

@end