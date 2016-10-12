//
//  CFXABProfile.m
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import "CFXABProfile.h"
#import <AddressBook/AddressBook.h>

@interface CFXABProfile ()
@property (nonatomic, readwrite) CFXABSocialNetworkType socialNetwork;
@property (nonatomic, readwrite) NSString               *username;
@property (nonatomic, readwrite) NSString               *userIdentifier;
@property (nonatomic, readwrite) NSURL                  *url;
@end


@implementation CFXABProfile

#pragma mark - life cycle

- (instancetype)initWithSocialDictionary:(NSDictionary *)dictionary {
    
    if (self = [super init]) {
        NSString *urlKey = (__bridge_transfer NSString *)kABPersonSocialProfileURLKey;
        NSString *usernameKey = (__bridge_transfer NSString *)kABPersonSocialProfileUsernameKey;
        NSString *userIdKey = (__bridge_transfer NSString *)kABPersonSocialProfileUserIdentifierKey;
        NSString *serviceKey = (__bridge_transfer NSString *)kABPersonSocialProfileServiceKey;
        _url = [NSURL URLWithString:dictionary[urlKey]];
        _username = dictionary[usernameKey];
        _userIdentifier = dictionary[userIdKey];
        _socialNetwork = [self socialNetworkTypeFromString:dictionary[serviceKey]];
    }
    
    return self;
}

#pragma mark - private

- (CFXABSocialNetworkType)socialNetworkTypeFromString:(NSString *)string {
    if ([string isEqualToString:(__bridge NSString *)kABPersonSocialProfileServiceFacebook]){
        return CFXABSocialNetworkFacebook;
    } else if ([string isEqualToString:(__bridge NSString *)kABPersonSocialProfileServiceTwitter]){
        return CFXABSocialNetworkTwitter;
    } else if ([string isEqualToString:(__bridge NSString *)kABPersonSocialProfileServiceLinkedIn]){
        return CFXABSocialNetworkLinkedIn;
    } else if ([string isEqualToString:(__bridge NSString *)kABPersonSocialProfileServiceFlickr]){
        return CFXABSocialNetworkFlickr;
    } else if ([string isEqualToString:(__bridge NSString *)kABPersonSocialProfileServiceGameCenter]){
        return CFXABSocialNetworkGameCenter;
    } else {
        return CFXABSocialNetworkUnknown;
    }
}

@end


@implementation CFXABPhoneWithTag

#pragma mark - life cycle

- (id)initWithPhone:(NSString *)phone originalTag:(NSString *)originalTag localizedTag:(NSString *)localizedTag {
    self = [super init];
    if (self){
        _phone = phone;
        _localizedTag = localizedTag;
        _originalTag = originalTag;
    }
    return self;
}

#pragma mark - overrides

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (%@) - %@", self.localizedTag, self.originalTag, self.phone];
}

@end


@implementation CFXABAddress

- (id)initWithAddressDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self){
        _street = dictionary[(__bridge NSString *)kABPersonAddressStreetKey];
        _city = dictionary[(__bridge NSString *)kABPersonAddressCityKey];
        _state = dictionary[(__bridge NSString *)kABPersonAddressStateKey];
        _zip = dictionary[(__bridge NSString *)kABPersonAddressZIPKey];
        _country = dictionary[(__bridge NSString *)kABPersonAddressCountryKey];
        _countryCode = dictionary[(__bridge NSString *)kABPersonAddressCountryCodeKey];
    }
    return self;
}

@end
