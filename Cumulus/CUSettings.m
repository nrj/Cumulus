//
//  CUSettings.m
//  Cumulus
//
//  Created by Nick Jensen on 01/05/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import "CUSettings.h"

NSString * const CUSecretAccessKeyServiceName = @"s3.amazonaws.com";

@implementation CUSettings

#pragma mark -
#pragma mark Singleton

+ (instancetype)sharedInstance {
    
    static CUSettings *sharedSettingsInstance = nil;
    static dispatch_once_t dispatchToken;
    dispatch_once(&dispatchToken, ^{
        sharedSettingsInstance = [[self alloc] init];
    });
    return sharedSettingsInstance;
}

#pragma mark -
#pragma mark Getters

- (BOOL)appearToBeValid {
 
    return [[self bucketName] length] && [[self accessKey] length] && [[self secretAccessKey] length];
}

- (NSString *)accessKey {
    
    if (!_accessKey) {
        _accessKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessKey"];
    }
    return _accessKey ?: @"";
}

- (NSString *)secretAccessKey {

    if (!_secretAccessKey) {
        NSString *account = [self accessKey];
        if ([account length]) {
            _secretAccessKey = [SSKeychain passwordForService:CUSecretAccessKeyServiceName account:account];
        }
    }
    return _secretAccessKey ?: @"";
}

- (NSString *)bucketName {
    
    if (!_bucketName) {
        _bucketName = [[NSUserDefaults standardUserDefaults] objectForKey:@"bucketName"];
    }
    return _bucketName ?: @"";
}

- (BOOL)isVirtuallyHosted {

    if (!_virtuallyHosted) {
        _virtuallyHosted = [[NSUserDefaults standardUserDefaults] objectForKey:@"virtuallyHosted"];
    }
    return [_virtuallyHosted boolValue];
}

#pragma mark -
#pragma mark Setters

- (void)setAccessKey:(NSString *)accessKey secretAccessKey:(NSString *)secretAccessKey {
    
    BOOL changed = NO;
    
    if (![[self accessKey] isEqualToString:accessKey]) {
        
        _accessKey = accessKey;
        
        [[NSUserDefaults standardUserDefaults] setObject:_accessKey forKey:@"accessKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        changed = YES;
    }
    
    if (![[self secretAccessKey] isEqualToString:secretAccessKey]) {

        _secretAccessKey = secretAccessKey;
        
        changed = YES;
    }
    
    if (changed) {
        
        NSString *account  = [self accessKey];
        NSString *password = [self secretAccessKey];
        
        if ([account length] && [password length]) {

            [SSKeychain setPassword:password forService:CUSecretAccessKeyServiceName account:accessKey];
        }
    }
}

- (void)setBucketName:(NSString *)bucketName {

    if (![_bucketName isEqualToString:bucketName]) {
        
        _bucketName = bucketName;
        
        [[NSUserDefaults standardUserDefaults] setObject:_bucketName forKey:@"bucketName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setVirtuallyHosted:(BOOL)virtuallyHosted {
    
    if ([_virtuallyHosted boolValue] != virtuallyHosted) {
        
        _virtuallyHosted = @(virtuallyHosted);
        
        [[NSUserDefaults standardUserDefaults] setObject:_virtuallyHosted forKey:@"virtuallyHosted"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
