//
//  CCCPushManager.h
//
//  Created by Chad Etzel on 4/26/14.
//  Copyright (c) 2014 Chad Etzel. MIT License. See LICENSE
//

typedef void(^CCCPushManagerChannelBlock)(NSArray *channels);

@protocol CCCPushManagerDelegate;

@interface CCCPushManager : NSObject

@property (nonatomic, weak) id<CCCPushManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *deviceTokenString;
@property (nonatomic, readonly) NSArray *channelArray;
@property (nonatomic, readonly) NSSet *channelSet;

+ (CCCPushManager *)sharedManager;

- (void)updateDeviceToken:(NSString *)deviceTokenString;
- (void)subscribeToChannels:(NSArray *)channels;
- (void)unsubscribeFromChannels:(NSArray *)channels;
- (void)getChannels:(CCCPushManagerChannelBlock)block;

@end

@protocol CCCPushManagerDelegate <NSObject>

- (NSString *)rootDomainForPushManager:(CCCPushManager *)pushManager;
- (BOOL)shouldUseSSLForPushManager:(CCCPushManager *)pushManager;

@end
