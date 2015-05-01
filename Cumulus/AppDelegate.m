//
//  AppDelegate.m
//  Cumulus
//
//  Created by Nick Jensen on 4/14/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import "AppDelegate.h"
#import "BaseConvert.h"
#import "S3.h"

#import "CUSettings.h"

@implementation AppDelegate

@synthesize window;
@synthesize accessKeyField;
@synthesize secretAccessKeyField;
@synthesize bucketNameField;
@synthesize virtuallyHostedCheckbox;
@synthesize checkSettingsButton;

@synthesize query;
@synthesize uploadQueue;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    uploadQueue = [[NSOperationQueue alloc] init];
    [uploadQueue setMaxConcurrentOperationCount:1];
    
    query = [[NSMetadataQuery alloc] init];
    [query setPredicate:[NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"]];
    [query startQuery];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMetadataQueryDidUpdateNotification:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:query];
    
    CUSettings *settings = [CUSettings sharedInstance];
    [accessKeyField setStringValue:[settings accessKey]];
    [secretAccessKeyField setStringValue:[settings secretAccessKey]];
    [bucketNameField setStringValue:[settings bucketName]];
    [virtuallyHostedCheckbox setState:[settings isVirtuallyHosted] ? NSOnState : NSOffState];

#ifdef DEBUG
    [[self window] makeKeyAndOrderFront:nil];
#else
    if (![settings appearToBeValid]) {
 
        [[self window] makeKeyAndOrderFront:nil];
    }
#endif
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    
    [[self window] makeKeyAndOrderFront:nil];
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    
    [self commitSettingsIfNeeded];
}

- (void)handleMetadataQueryDidUpdateNotification:(NSNotification *)note {
    
    NSArray *added = [[note userInfo] objectForKey:(NSString *)kMDQueryUpdateAddedItems];
    
    if ([added count] > 0) {
        
        NSMetadataItem *item = [added firstObject];
        NSString *screenshotFilePath = [item valueForKey:NSMetadataItemPathKey];
    
        if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotFilePath isDirectory:nil]) {

            [self commitSettingsIfNeeded];
            [self uploadScreenshotAtFilePath:screenshotFilePath];
        }
    }
}

#pragma mark -
#pragma mark Upload

- (void)uploadScreenshotAtFilePath:(NSString *)filePath {

    // Check settings are at least populated
    CUSettings *settings = [CUSettings sharedInstance];
    if (![settings appearToBeValid]) {
        return;
    }
    
    // Load settings
    NSString *accessKey = [settings accessKey];
    NSString *secretAccessKey = [settings secretAccessKey];
    NSString *bucketName = [settings bucketName];
    BOOL isVirtuallyHosted = [settings isVirtuallyHosted];
    
    // Get the content length
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
    NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
    NSString *contentLength = [[NSNumber numberWithInteger:fileSize] stringValue];
    
    // Get the content type
    NSString *fileExtension = [filePath pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *contentType = (__bridge_transfer NSString *)MIMEType;
    
    // Generate a filename
    NSInteger timestamp = floor([[NSDate date] timeIntervalSince1970]);
    NSString *base36Timestamp = [decToOther((int)timestamp, 36) lowercaseString];
    NSString *uploadFilename = [NSString stringWithFormat:@"%@.%@", base36Timestamp, fileExtension];
    
    // Access control
    NSString *ACLField = @"x-amz-acl";
    NSString *ACLValue = @"public-read";
    
    // Create the authorization header
    NSString *authACL = [NSString stringWithFormat:@"%@:%@", ACLField, ACLValue];
    NSString *authResource = [NSString stringWithFormat:@"/%@/%@", bucketName, uploadFilename];
    NSString *authDate = S3DateString();
    NSString *authHeader = S3AuthHeader(@"PUT", contentType, authDate, authACL, authResource, accessKey, secretAccessKey);
    
    // Create the HTTP request
    NSString *URLString = [NSString stringWithFormat:@"http://%@.s3.amazonaws.com/%@", bucketName, uploadFilename];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer new] requestWithMethod:@"PUT" URLString:URLString parameters:nil error:nil];
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:[fileURL path]];
    [request setHTTPBodyStream:inputStream];
    [request setValue:authDate forHTTPHeaderField:@"Date"];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:ACLValue forHTTPHeaderField:ACLField];
    
    // Queue the upload operation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[AFXMLParserResponseSerializer new]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *URLToCopy;
        if (!isVirtuallyHosted) {
            URLToCopy = [NSString stringWithFormat:@"http://%@.s3.amazonaws.com/%@", bucketName, uploadFilename];
        }
        else {
            URLToCopy = [NSString stringWithFormat:@"http://%@/%@", bucketName, uploadFilename];
        }

        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
        [pb setString:URLToCopy forType:NSStringPboardType];
        
        [self displayNotificationWithTitle:@"Screenshot Uploaded" body:@"Link copied to clipboard." URL:URLToCopy success:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSInteger statusCode = [[operation response] statusCode];
        NSString *errorMessage;
        if (statusCode >= 400 && statusCode <= 499) {
            errorMessage = @"Your S3 credentials appear to be invalid.";
        }
        else {
            errorMessage = [error localizedDescription];
        }
        [self displayNotificationWithTitle:@"Screenshot Upload Failure" body:errorMessage URL:nil success:NO];
    }];
    [uploadQueue addOperation:operation];
}

#pragma mark -
#pragma mark Notification

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    
    BOOL successNotification = [[[notification userInfo] objectForKey:@"success"] boolValue];
    
    if (successNotification) {
        
        NSString *URLString = [[notification userInfo] objectForKey:@"URL"];
        NSURL *URL = [NSURL URLWithString:URLString];
        if (URL) {
            [[NSWorkspace sharedWorkspace] openURL:URL];
        }
    }
    else {

        [NSApp activateIgnoringOtherApps:YES];
        [[self window] makeKeyAndOrderFront:nil];
    }
}

- (void)displayNotificationWithTitle:(NSString *)title body:(NSString *)body URL:(NSString *)URL success:(BOOL)success {
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:title];
    [notification setInformativeText:body];
    [notification setSoundName:nil];

    NSDictionary *userInfo;
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                @(success), @"success",
                URL ?: @"", @"URL", nil];
    
    [notification setUserInfo:userInfo];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark -
#pragma mark Settings

- (void)controlTextDidChange:(NSNotification *)notification {
    
    NSTextField *textField = [notification object];

    if (textField == accessKeyField ||
        textField == secretAccessKeyField ||
        textField == bucketNameField) {
        
        _settingsDirty = YES;
    }
}

- (IBAction)virtualHostingDidChange:(id)sender {
    
    _settingsDirty = YES;
}

- (void)commitSettingsIfNeeded {
    
    if (_settingsDirty) {
        
        CUSettings *settings = [CUSettings sharedInstance];
        
        NSString *accessKey;
        accessKey = [[accessKeyField stringValue] stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString *secretAccessKey;
        secretAccessKey = [[secretAccessKeyField stringValue] stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [settings setAccessKey:accessKey secretAccessKey:secretAccessKey];
        
        NSString *bucketName;
        bucketName = [[bucketNameField stringValue] stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [settings setBucketName:bucketName];
        
        BOOL virtuallyHosted = ([virtuallyHostedCheckbox state] == NSOnState);
        [settings setVirtuallyHosted:virtuallyHosted];
        
        _settingsDirty = NO;
    }
}

- (IBAction)checkSettings:(id)sender {
    
}

- (IBAction)handleMoreAboutVirtualHostingLink:(id)sender {

    NSURL *URL = [NSURL URLWithString:@"http://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html#VirtualHostingCustomURLs"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

@end