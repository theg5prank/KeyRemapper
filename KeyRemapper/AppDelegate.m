//
//  AppDelegate.m
//  KeyRemapper
//
//  Created by Conor Hughes on 9/27/16.
//  Copyright © 2016 Conor Hughes. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "AppDelegate.h"
#import "KRStatusBarMenu.h"

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef  event, void * __nullable userInfo);

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate {
    NSDictionary<NSNumber *, NSString *> *_pid2bundleIDCache;
    NSStatusItem *_statusItem;
}

- (CGEventRef)filterEventForTerminalBehaviors:(CGEventRef)event
{
    pid_t target = (pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID);
    NSString *bundleID = _pid2bundleIDCache[@(target)];
    if ( !bundleID ) {
        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:target];
        bundleID = app.bundleIdentifier;
        NSLog(@"Didn't have a mapping for %d in the cache (found %@)", (int)target, bundleID);
    }
    
    UniChar buf[16];
    const UniCharCount buflen = sizeof(buf) / sizeof(buf[0]);
    UniCharCount actualLength;
    CGEventKeyboardGetUnicodeString(event, buflen, &actualLength, buf);
    if ( actualLength > buflen ) {
        NSLog(@"%lu UniChars is way too many", (unsigned long)actualLength);
        return event;
    }
    NSString *str = [[NSString alloc] initWithBytes:buf length:actualLength * sizeof(UniChar) encoding:NSUTF16LittleEndianStringEncoding];
    
    CGEventFlags flags = CGEventGetFlags(event);
    CGEventFlags ignorableFlags = kCGEventFlagMaskAlphaShift;
    flags &= ~ignorableFlags;
    CGEventFlags bannedFlags = kCGEventFlagMaskCommand | kCGEventFlagMaskShift | kCGEventFlagMaskAlternate;
    
    if ((flags & kCGEventFlagMaskControl) && (flags & bannedFlags) == 0 && [str isEqualToString:@"/"] && [bundleID isEqualToString:@"com.apple.Terminal"]) {
        // This is sufficient for Terminal. Otherwise we'd have to lookup the right virtual key sequence to type a _, blah blah blah.
        UniChar character = 31;
        CGEventKeyboardSetUnicodeString(event, 1, &character);
    }
    
    return event;
}

- (CGEventRef)filterEvent:(CGEventRef)event ofType:(CGEventType)type fromTap:(CGEventTapProxy)tapProxy
{
    if ( type != kCGEventKeyUp && type != kCGEventKeyDown ) {
        NSLog(@"unknown event.");
        return event;
    }
    event = [self filterEventForTerminalBehaviors:event];
    return event;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    CFMutableDictionaryRef opts = CFDictionaryCreateMutable(NULL, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(opts, kAXTrustedCheckOptionPrompt, kCFBooleanTrue);
    Boolean result = AXIsProcessTrustedWithOptions(opts);
    while (!result)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No AX."];
        [alert addButtonWithTitle:@"try again"];
        [alert addButtonWithTitle:@"quit"];
        NSModalResponse response = [alert runModal];
        if ( response == NSAlertSecondButtonReturn )
        {
            [[NSApplication sharedApplication] terminate:self];
        }
        result = AXIsProcessTrustedWithOptions(opts);
    }
    
    NSMenu *menu = [[KRStatusBarMenu alloc] initWithTitle:@"KR"];
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [[_statusItem button] setTitle:menu.title];
    [_statusItem setMenu:menu];
    
    CFMachPortRef tap = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventKeyDown), eventTapCallback, (__bridge void *)(self));
    CFRunLoopSourceRef runloopSource = CFMachPortCreateRunLoopSource(NULL, tap, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runloopSource, kCFRunLoopCommonModes);
    [[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:0 context:nil];
    [self updatePid2BundleIDCache];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"runningApplications"] ) {
        [self updatePid2BundleIDCache];
    }
}

- (void)updatePid2BundleIDCache
{
    NSArray<NSRunningApplication *> *newApps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[newApps count]];
    for ( NSRunningApplication *app in newApps ) {
        dict[@(app.processIdentifier)] = app.bundleIdentifier;
    }
    _pid2bundleIDCache = dict;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)quitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

@end

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef  event, void * __nullable userInfo)
{
    return [(__bridge AppDelegate *)userInfo filterEvent:event ofType:type fromTap:proxy];
}
