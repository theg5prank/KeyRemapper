//
//  KRStatusBarMenu.m
//  KeyRemapper
//
//  Created by Conor Hughes on 9/29/16.
//  Copyright © 2016 Conor Hughes. All rights reserved.
//

#import "KRStatusBarMenu.h"


@implementation KRStatusBarMenu

- (instancetype)initWithTitle:(NSString *)title
{
    if ( (self = [super initWithTitle:title]) ) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ( (self = [super initWithCoder:decoder]) ) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    [self setTitle:@"KR"];
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quitApp:) keyEquivalent:@""];
    [self addItem:quitItem];
}


@end
