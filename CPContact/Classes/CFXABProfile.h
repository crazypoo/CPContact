//
//  CFXABProfile.h
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CFXABSocialNetworkType) {
    CFXABSocialNetworkUnknown    = 0,
    CFXABSocialNetworkFacebook   = 1,
    CFXABSocialNetworkTwitter    = 2,
    CFXABSocialNetworkLinkedIn   = 3,
    CFXABSocialNetworkFlickr     = 4,
    CFXABSocialNetworkGameCenter = 5
};

@interface CFXABProfile : NSObject

@property (nonatomic, readonly) CFXABSocialNetworkType socialNetwork;
@property (nonatomic, readonly) NSString              *username;
@property (nonatomic, readonly) NSString              *userIdentifier;
@property (nonatomic, readonly) NSURL                 *url;

- (instancetype)initWithSocialDictionary:(NSDictionary *)dictionary;

@end


@interface CFXABPhoneWithTag : NSObject

@property (nonatomic, readonly) NSString *phone;
@property (nonatomic, readonly) NSString *originalTag;
@property (nonatomic, readonly) NSString *localizedTag;

- (id)initWithPhone:(NSString *)phone
      originalTag:(NSString *)originalTag
     localizedTag:(NSString *)localizedTag;

@end


@interface CFXABAddress : NSObject

@property (nonatomic, readonly) NSString *street;
@property (nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSString *state;
@property (nonatomic, readonly) NSString *zip;
@property (nonatomic, readonly) NSString *country;
@property (nonatomic, readonly) NSString *countryCode;

- (id)initWithAddressDictionary:(NSDictionary *)dictionary;

@end
