//
//  KRStatusBarMenu.h
//  KeyRemapper
//
//  Created by Conor Hughes on 9/29/16.
//  Copyright © 2016 Conor Hughes. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (KRStatusBarMenuSentActions)
- (void)quitApp:(id)sender;
@end


@interface KRStatusBarMenu : NSMenu

@end
