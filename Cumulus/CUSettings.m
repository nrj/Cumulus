//
//  CUSettings.m
//  Cumulus
//
//  Created by Nick Jensen on 01/05/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import "CUSettings.h"

NSString * const CUSettingsErrorDomain        = @"io.nrj.cumulus.error";
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

- (NSError *)errorCheck {
    
    NSString *errorMessage = nil;
    NSMutableArray *missingSettings = [NSMutableArray array];
    NSDictionary *requiredSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"accessKey", @"Access Key",
                                      @"secretAccessKey", @"Secret Access Key",
                                      @"bucketName", @"Bucket Name", nil];
    
    for (NSString *key in [requiredSettings allKeys]) {

        SEL selector = NSSelectorFromString([requiredSettings objectForKey:key]);
        IMP imp = [self methodForSelector:selector];
        NSString *(*func)(id, SEL) = (void *)imp;
        NSString *value = func(self, selector);

        if ([value length] == 0) {

            [missingSettings addObject:key];
        }
    }
    
    if ([missingSettings count] > 0) {
    
        errorMessage = [NSString stringWithFormat:@"The following settings are missing: %@.",
                        [missingSettings componentsJoinedByString:@", "]];
    }
    else if ([self isVirtuallyHosted]) {
            
        NSCharacterSet *disallowed = [[NSCharacterSet URLHostAllowedCharacterSet] invertedSet];
        NSString *bucketName = [self bucketName];
        NSRange badCharacters = [bucketName rangeOfCharacterFromSet:disallowed];
        NSRange dotRange = [bucketName rangeOfString:@"."];
        NSInteger length = [bucketName length];

        if ((badCharacters.location != NSNotFound) || (dotRange.location == NSNotFound || dotRange.location < 1 || length < 5)) {

            errorMessage = @"Bucket name is not DNS-compatible (required for Virtual Hosting).";
        }
    }
    
    NSError *error = nil;

    if (errorMessage) {
    
        error = [NSError errorWithDomain:CUSettingsErrorDomain code:-1 userInfo:
                 [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
    }
    
    return error;
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
