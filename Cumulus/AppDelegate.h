//
//  AppDelegate.h
//  Cumulus
//
//  Created by Nick Jensen on 4/14/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSMetadataQueryDelegate, NSWindowDelegate> {
@private
    BOOL _settingsDirty;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *accessKeyField;
@property (weak) IBOutlet NSTextField *secretAccessKeyField;
@property (weak) IBOutlet NSTextField *bucketNameField;
@property (weak) IBOutlet NSButton *virtuallyHostedCheckbox;
@property (weak) IBOutlet NSButton *checkSettingsButton;

@property (nonatomic, readonly) NSMetadataQuery *query;
@property (nonatomic, readonly) NSOperationQueue *uploadQueue;

@end

