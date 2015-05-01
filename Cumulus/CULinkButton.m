//
//  CULinkButton.m
//  Cumulus
//
//  Created by Nick Jensen on 01/05/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import "CULinkButton.h"

@implementation CULinkButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        
        [self setBordered:NO];
        [self setButtonType:NSMomentaryChangeButton];
        
        NSString *title = [self title];
        NSMutableDictionary *attributes;
        attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSColor controlShadowColor], NSForegroundColorAttributeName,
                      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
                      [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
                      nil];
        NSAttributedString *attrTitle;
        attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        
        [attributes setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
        NSAttributedString *attrAltTitle;
        attrAltTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        
        [self setAttributedTitle:attrTitle];
        [self setAttributedAlternateTitle:attrAltTitle];
    }
    return self;
}

- (void)resetCursorRects {
    
    [super resetCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

@end
