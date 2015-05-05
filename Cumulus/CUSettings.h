//
//  CUSettings.h
//  Cumulus
//
//  Created by Nick Jensen on 01/05/15.
//  Copyright (c) 2015 Nick Jensen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SSKeychain/SSKeychain.h>

@interface CUSettings : NSObject {
@private
    NSString *_accessKey;
    NSString *_secretAccessKey;
    NSString *_bucketName;
    NSNumber *_virtuallyHosted;
}

+ (instancetype)sharedInstance;

- (NSError *)errorCheck;

- (void)setAccessKey:(NSString *)accessKey secretAccessKey:(NSString *)secretAccessKey;
- (NSString *)accessKey;
- (NSString *)secretAccessKey;

- (void)setBucketName:(NSString *)bucketName;
- (NSString *)bucketName;

- (void)setVirtuallyHosted:(BOOL)virtuallyHosted;
- (BOOL)isVirtuallyHosted;

@end
