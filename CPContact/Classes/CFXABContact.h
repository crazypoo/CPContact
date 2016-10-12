//
//  CFXABContact.h
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@class CFXABContact;

typedef NS_ENUM(NSUInteger, CFXABAccess) {
    CFXABAccessUnknown = 0,
    CFXABAccessGranted = 1,
    CFXABAccessDenied  = 2
};

typedef NS_OPTIONS(NSUInteger , CFXABContactField) {
    CFXABContactFieldFirstName        = 1 << 0,
    CFXABContactFieldLastName         = 1 << 1,
    CFXABContactFieldCompany          = 1 << 2,
    CFXABContactFieldPhones           = 1 << 3,
    CFXABContactFieldEmails           = 1 << 4,
    CFXABContactFieldPhoto            = 1 << 5,
    CFXABContactFieldThumbnail        = 1 << 6,
    CFXABContactFieldphonesWithTags = 1 << 7,
    CFXABContactFieldCompositeName    = 1 << 8,
    CFXABContactFieldAddresses        = 1 << 9,
    CFXABContactFieldRecordID         = 1 << 10,
    CFXABContactFieldCreationDate     = 1 << 11,
    CFXABContactFieldModificationDate = 1 << 12,
    CFXABContactFieldMiddleName       = 1 << 13,
    CFXABContactFieldSocialProfiles   = 1 << 14,
    CFXABContactFieldNote             = 1 << 15,
    CFXABContactFieldLinkedRecordIDs  = 1 << 16,
    CFXABContactFieldJobTitle         = 1 << 17,
    CFXABContactFieldDefault          = CFXABContactFieldFirstName | CFXABContactFieldLastName |CFXABContactFieldPhones,
    CFXABContactFieldAll              = 0xFFFFFFFF
};

typedef BOOL(^CFXABContactFilterBlock)(CFXABContact *contact);

@interface CFXABContact : NSObject

@property (nonatomic, readonly) CFXABContactField fieldMask;
@property (nonatomic, readonly) NSString        *firstName;
@property (nonatomic, readonly) NSString        *middleName;
@property (nonatomic, readonly) NSString        *lastName;
@property (nonatomic, readonly) NSString        *compositeName;
@property (nonatomic, readonly) NSString        *company;
@property (nonatomic, readonly) NSString        *jobTitle;
@property (nonatomic, readonly) NSArray         *phones;
@property (nonatomic, readonly) NSArray         *phonesWithTags;
@property (nonatomic, readonly) NSArray         *emails;
@property (nonatomic, readonly) NSArray         *addresses;
@property (nonatomic, readonly) UIImage         *photo;
@property (nonatomic, readonly) UIImage         *thumbnail;
@property (nonatomic, readonly) NSNumber        *recordID;
@property (nonatomic, readonly) NSDate          *creationDate;
@property (nonatomic, readonly) NSDate          *modificationDate;
@property (nonatomic, readonly) NSArray         *socialProfiles;
@property (nonatomic, readonly) NSString        *note;
@property (nonatomic, readonly) NSArray         *linkedRecordIDs;

- (id)initWithRecordRef:(ABRecordRef)recordRef fieldMask:(CFXABContactField)fieldMask;

@end
