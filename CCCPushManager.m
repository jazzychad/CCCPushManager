//
//  CCCPushManager.m
//
//  Created by Chad Etzel on 4/26/14.
//  Copyright (c) 2014 Chad Etzel. MIT License. See LICENSE
//

#import <AFNetworking/AFNetworking.h>
#import "CCCPushManager.h"

@implementation CCCPushManager {
    NSMutableArray *_subscribeQueue;
    NSMutableArray *_unsubscribeQueue;
}

+ (CCCPushManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static CCCPushManager *sSharedManager;
    dispatch_once(&onceToken, ^{
        sSharedManager = [[self alloc] init];
    });

    return sSharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _subscribeQueue = [NSMutableArray array];
        _unsubscribeQueue = [NSMutableArray array];
    }
    return self;
}

- (void)updateDeviceToken:(NSString *)deviceTokenString
{
    _deviceTokenString = [deviceTokenString copy];
    [self _updateDeviceToken:deviceTokenString channels:@[@"b"] unsubscribe:NO]; // subscribe to broadcast channel by default
}

- (void)subscribeToChannels:(NSArray *)channels
{
    [self _updateDeviceToken:_deviceTokenString channels:channels unsubscribe:NO];
}

- (void)unsubscribeFromChannels:(NSArray *)channels
{
    [self _updateDeviceToken:_deviceTokenString channels:channels unsubscribe:YES];
}

- (void)_updateDeviceToken:(NSString *)deviceTokenString channels:(NSArray *)channels unsubscribe:(BOOL)shouldUnsubscribe
{

    if (!_deviceTokenString) {
        NSLog(@"no device token is registered! adding to queue then bailing...");
        if (shouldUnsubscribe) {
            [_unsubscribeQueue addObjectsFromArray:channels];
        } else {
            [_subscribeQueue addObjectsFromArray:channels];
        }
        return;
    }


    NSString *environment = nil;
#ifdef DEBUG
    environment = @"dev";
#else
    environment = @"prod";
#endif

    NSString *baseURLString = [NSString stringWithFormat:@"%@://%@/", ([self.delegate shouldUseSSLForPushManager:self] ? @"https" : @"http"), [self.delegate rootDomainForPushManager:self]];
    NSURL *baseURL = [NSURL URLWithString:baseURLString];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:deviceTokenString forKey:@"deviceToken"];

    if (channels.count) {
        [params setObject:[channels componentsJoinedByString:@","] forKey:@"channels"];
    }

    if (shouldUnsubscribe) {
        [params setObject:@"true" forKey:@"unsubscribe"];
    }

    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];

    [client postPath:[NSString stringWithFormat:@"%@/updateDeviceToken", environment] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success updating token!");

        if (_subscribeQueue.count) {
            NSArray *subscribeQueue = [_subscribeQueue copy];
            _subscribeQueue = [NSMutableArray array];
            [self subscribeToChannels:subscribeQueue];
        }

        if (_unsubscribeQueue.count) {
            NSArray *unsubscribeQueue = [_unsubscribeQueue copy];
            _unsubscribeQueue = [NSMutableArray array];
            [self unsubscribeFromChannels:unsubscribeQueue];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure updating token! %@", error);
        if (shouldUnsubscribe) {
            [_unsubscribeQueue addObjectsFromArray:channels];
        } else {
            [_subscribeQueue addObjectsFromArray:channels];
        }
    }];

}

- (void)getChannels:(CCCPushManagerChannelBlock)block
{
    if (!_deviceTokenString) {
        if (block) {
            block(nil);
        }
    } else {
        NSString *baseURLString = [NSString stringWithFormat:@"%@://%@/", ([self.delegate shouldUseSSLForPushManager:self] ? @"https" : @"http"), [self.delegate rootDomainForPushManager:self]];
        NSURL *baseURL = [NSURL URLWithString:baseURLString];

        AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];

        [client getPath:[NSString stringWithFormat:@"channel_list/%@", _deviceTokenString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

            if ([responseObject isKindOfClass:[NSData class]]) {
                NSLog(@"channels response: %@", responseObject);
                NSLog(@"response class: %@", NSStringFromClass([responseObject class]));

                NSData *responseData = (NSData *)responseObject;
                NSArray *channelArray = nil;

                if (responseData.length) {
                    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"responseString: %@", responseString);

                    channelArray = [responseString componentsSeparatedByString:@","];
                    NSLog(@"channelArray: %@", channelArray);

                    _channelArray = [channelArray copy];
                    _channelSet = [NSSet setWithArray:channelArray];
                }
                
                if (block) {
                    block(channelArray);
                }
            } else {
                NSLog(@"got some other kind of class! %@", NSStringFromClass([responseObject class]));
                if (block) {
                    block(nil);
                }
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (block) {
                block(nil);
            }
        }];
    }
}

@end
