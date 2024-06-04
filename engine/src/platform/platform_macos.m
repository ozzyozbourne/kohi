#include "platform/platform.h"

#if defined(KPLATFORM_APPLE)

#include "core/logger.h"

#include <crt_externs.h>
#include <mach/mach_time.h>

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class ApplicationDelegate;
@class WindowDelegate;
@class ContentView;

typedef struct internal_state {
  ApplicationDelegate *app_delegate;
  WindowDelegate *wnd_delegate;
  NSWindow *window;
  ContentView *view;
  CAMetalLayer *layer;
  b8 quit_flagged;
} internal_state;

@interface WindowDelegate : NSObject <NSWindowDelegate> {
  internal_state *state;
}

- (instancetype)initWithState:(internal_state *)init_state;

@end // WindowDelegate

@implementation WindowDelegate

- (instancetype)initWithState:(internal_state *)init_state {
  self = [super init];

  if (self != nil) {
    state = init_state;
    state->quit_flagged = FALSE;
  }

  return self;
}

- (BOOL)windowShouldClose:(id)sender {
  state->quit_flagged = TRUE;
  return YES;
}

- (void)windowDidResize:(NSNotification *)notification {
  const NSRect contentRect = [state->view frame];
  const NSRect framebufferRect = [state->view convertRectToBacking:contentRect];
}

- (void)windowDidMiniaturize:(NSNotification *)notification {
  [state->window miniaturize:nil];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification {
  const NSRect contentRect = [state->view frame];
  const NSRect framebufferRect = [state->view convertRectToBacking:contentRect];

  [state->window deminiaturize:nil];
}

@end // WindowDelegate

@interface ContentView : NSView <NSTextInputClient> {
  NSWindow *window;
  NSTrackingArea *trackingArea;
  NSMutableAttributedString *markedText;
}

- (instancetype)initWithWindow:(NSWindow *)initWindow;

@end // ContentView

@implementation ContentView

- (instancetype)initWithWindow:(NSWindow *)initWindow {
  self = [super init];
  if (self != nil) {
    window = initWindow;
  }

  return self;
}

- (BOOL)canBecomeKeyView {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)wantsUpdateLayer {
  return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
  return YES;
}

- (void)insertText:(id)string replacementRange:(NSRange)replacementRange {
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange {
}

- (void)unmarkText {
}

// Defines a constant for empty ranges in NSTextInputClient
static const NSRange kEmptyRange = {NSNotFound, 0};

- (NSRange)selectedRange {
  return kEmptyRange;
}

- (NSRange)markedRange {
  return kEmptyRange;
}

- (BOOL)hasMarkedText {
  return FALSE;
}

- (nullable NSAttributedString *)
    attributedSubstringForProposedRange:(NSRange)range
                            actualRange:(nullable NSRangePointer)actualRange {
  return nil;
}

- (NSArray<NSAttributedStringKey> *)validAttributesForMarkedText {
  return [NSArray array];
}

- (NSRect)firstRectForCharacterRange:(NSRange)range
                         actualRange:(nullable NSRangePointer)actualRange {
  return NSMakeRect(0, 0, 0, 0);
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point {
  return 0;
}

@end // ContentView

@interface ApplicationDelegate : NSObject <NSApplicationDelegate> {
}

@end // ApplicationDelegate

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // Posting an empty event at start
  @autoreleasepool {

    NSEvent *event = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                        location:NSMakePoint(0, 0)
                                   modifierFlags:0
                                       timestamp:0
                                    windowNumber:0
                                         context:nil
                                         subtype:0
                                           data1:0
                                           data2:0];
    [NSApp postEvent:event atStart:YES];

  } // autoreleasepool

  [NSApp stop:nil];
}

@end // ApplicationDelegate

b8 platform_startup(platform_state *plat_state, const char *application_name,
                    i32 x, i32 y, i32 width, i32 height) {
  plat_state->internal_state = malloc(sizeof(internal_state));
  internal_state *state = (internal_state *)plat_state->internal_state;

  @autoreleasepool {

    [NSApplication sharedApplication];

    // App delegate creation
    state->app_delegate = [[ApplicationDelegate alloc] init];
    if (!state->app_delegate) {
      KERROR("Failed to create application delegate")
      return FALSE;
    }
    [NSApp setDelegate:state->app_delegate];

    // Window delegate creation
    state->wnd_delegate = [[WindowDelegate alloc] initWithState:state];
    if (!state->wnd_delegate) {
      KERROR("Failed to create window delegate")
      return FALSE;
    }

    // Window creation
    state->window =
        [[NSWindow alloc] initWithContentRect:NSMakeRect(x, y, width, height)
                                    styleMask:NSWindowStyleMaskMiniaturizable |
                                              NSWindowStyleMaskTitled |
                                              NSWindowStyleMaskClosable |
                                              NSWindowStyleMaskResizable
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    if (!state->window) {
      KERROR("Failed to create window");
      return FALSE;
    }

    // Layer creation
    state->layer = [CAMetalLayer layer];
    if (!state->layer) {
      KERROR("Failed to create layer for view");
    }

    // View creation
    state->view = [[ContentView alloc] initWithWindow:state->window];
    [state->view setLayer:state->layer];
    [state->view setWantsLayer:YES];

    // Setting window properties
    [state->window setLevel:NSNormalWindowLevel];
    [state->window setContentView:state->view];
    [state->window makeFirstResponder:state->view];
    [state->window setTitle:@(application_name)];
    [state->window setDelegate:state->wnd_delegate];
    [state->window setAcceptsMouseMovedEvents:YES];
    [state->window setRestorable:NO];

    if (![[NSRunningApplication currentApplication] isFinishedLaunching])
      [NSApp run];

    // Making the app a proper UI app since we're unbundled
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Putting window in front on launch
    [NSApp activateIgnoringOtherApps:YES];
    [state->window makeKeyAndOrderFront:nil];

    return TRUE;

  } // autoreleasepool
}

void platform_shutdown(platform_state *plat_state) {
  // Simply cold-cast to the known type.
  internal_state *state = (internal_state *)plat_state->internal_state;

  @autoreleasepool {

    if (state->app_delegate) {
      [NSApp setDelegate:nil];
      [state->app_delegate release];
      state->app_delegate = nil;
    }

    if (state->wnd_delegate) {
      [state->window setDelegate:nil];
      [state->wnd_delegate release];
      state->wnd_delegate = nil;
    }

    if (state->view) {
      [state->view release];
      state->view = nil;
    }

    if (state->window) {
      [state->window close];
      state->window = nil;
    }
  }
}

b8 platform_pump_messages(platform_state *plat_state) {
  // Simply cold-cast to the known type.
  internal_state *state = (internal_state *)plat_state->internal_state;

  @autoreleasepool {

    NSEvent *event;

    for (;;) {
      event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                 untilDate:[NSDate distantPast]
                                    inMode:NSDefaultRunLoopMode
                                   dequeue:YES];

      if (!event)
        break;

      [NSApp sendEvent:event];
    }

  } // autoreleasepool

  return !state->quit_flagged;
}

void *platform_allocate(u64 size, b8 aligned) { return malloc(size); }

void platform_free(void *block, b8 aligned) { free(block); }

void *platform_zero_memory(void *block, u64 size) {
  return memset(block, 0, size);
}

void *platform_copy_memory(void *dest, const void *source, u64 size) {
  return memcpy(dest, source, size);
}

void *platform_set_memory(void *dest, i32 value, u64 size) {
  return memset(dest, value, size);
}

void platform_console_write(const char *message, u8 colour) {
  // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
  const char *colour_strings[] = {"0;41", "1;31", "1;33",
                                  "1;32", "1;34", "1;30"};
  printf("\033[%sm%s\033[0m", colour_strings[colour], message);
}

void platform_console_write_error(const char *message, u8 colour) {
  // FATAL,ERROR,WARN,INFO,DEBUG,TRACE
  const char *colour_strings[] = {"0;41", "1;31", "1;33",
                                  "1;32", "1;34", "1;30"};
  printf("\033[%sm%s\033[0m", colour_strings[colour], message);
}

f64 platform_get_absolute_time() { return mach_absolute_time(); }

void platform_sleep(u64 ms) {
#if _POSIX_C_SOURCE >= 199309L
  struct timespec ts;
  ts.tv_sec = ms / 1000;
  ts.tv_nsec = (ms % 1000) * 1000 * 1000;
  nanosleep(&ts, 0);
#else
  if (ms >= 1000) {
    sleep(ms / 1000);
  }
  usleep((ms % 1000) * 1000);
#endif
}

#endif // SLN_PLATFORM_MACOS
