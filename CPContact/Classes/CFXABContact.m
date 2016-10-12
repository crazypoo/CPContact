//
//  CFXABContact.m
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import "CFXABContact.h"
#import "CFXABProfile.h"


@implementation CFXABContact

#pragma mark - life cycle

- (id)initWithRecordRef:(ABRecordRef)recordRef fieldMask:(CFXABContactField)fieldMask {
    self = [super init];
    if (self){
        _fieldMask = fieldMask;
        if (fieldMask & CFXABContactFieldFirstName){
            _firstName = [self stringProperty:kABPersonFirstNameProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldMiddleName){
            _middleName = [self stringProperty:kABPersonMiddleNameProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldLastName){
            _lastName = [self stringProperty:kABPersonLastNameProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldCompositeName){
            _compositeName = [self compositeNameFromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldCompany){
            _company = [self stringProperty:kABPersonOrganizationProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldJobTitle){
            _jobTitle = [self stringProperty:kABPersonJobTitleProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldPhones){
            _phones = [self arrayProperty:kABPersonPhoneProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldphonesWithTags){
            _phonesWithTags = [self arrayOfphonesWithTagsFromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldEmails){
            _emails = [self arrayProperty:kABPersonEmailProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldPhoto){
            _photo = [self imagePropertyFullSize:YES fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldThumbnail){
            _thumbnail = [self imagePropertyFullSize:NO fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldAddresses){
            NSMutableArray *addresses = [[NSMutableArray alloc] init];
            NSArray *array = [self arrayProperty:kABPersonAddressProperty fromRecord:recordRef];
            for (NSDictionary *dictionary in array){
                CFXABAddress *address = [[CFXABAddress alloc] initWithAddressDictionary:dictionary];
                [addresses addObject:address];
            }
            _addresses = addresses.copy;
        }
        if (fieldMask & CFXABContactFieldRecordID){
            _recordID = @(ABRecordGetRecordID(recordRef));
        }
        if (fieldMask & CFXABContactFieldCreationDate){
            _creationDate = [self dateProperty:kABPersonCreationDateProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldModificationDate){
            _modificationDate = [self dateProperty:kABPersonModificationDateProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldSocialProfiles){
            NSMutableArray *profiles = [[NSMutableArray alloc] init];
            NSArray *array = [self arrayProperty:kABPersonSocialProfileProperty fromRecord:recordRef];
            for (NSDictionary *dictionary in array){
                CFXABProfile *profile = [[CFXABProfile alloc] initWithSocialDictionary:dictionary];
                [profiles addObject:profile];
            }
            
            _socialProfiles = profiles;
        }
        if (fieldMask & CFXABContactFieldNote){
            _note = [self stringProperty:kABPersonNoteProperty fromRecord:recordRef];
        }
        if (fieldMask & CFXABContactFieldLinkedRecordIDs){
            NSMutableOrderedSet *linkedRecordIDs = [[NSMutableOrderedSet alloc] init];
            
            CFArrayRef linkedPeopleRef = ABPersonCopyArrayOfAllLinkedPeople(recordRef);
            CFIndex count = CFArrayGetCount(linkedPeopleRef);
            for (CFIndex i = 0; i < count; i++){
                ABRecordRef linkedRecordRef = CFArrayGetValueAtIndex(linkedPeopleRef, i);
                [linkedRecordIDs addObject:@(ABRecordGetRecordID(linkedRecordRef))];
            }
            if (linkedPeopleRef) {
                CFRelease(linkedPeopleRef);
            }
            
            [linkedRecordIDs removeObject:@(ABRecordGetRecordID(recordRef))];
            _linkedRecordIDs = linkedRecordIDs.array;
        }
    }
    return self;
}

#pragma mark - private methods

- (NSString *)stringProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef {
    CFTypeRef valueRef = (ABRecordCopyValue(recordRef, property));
    return (__bridge_transfer NSString *)valueRef;
}

- (NSArray *)arrayProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef {
    __block NSMutableArray *array = [[NSMutableArray alloc] init];
    [self enumerateMultiValueOfProperty:property fromRecord:recordRef
                              withBlock:^(ABMultiValueRef multiValue, NSUInteger index){
                                  CFTypeRef value = ABMultiValueCopyValueAtIndex(multiValue, index);
                                  NSString *string = (__bridge_transfer NSString *)value;
                                  if (string){
                                      [array addObject:string];
                                  }
                              }];
    return array.copy;
}

- (NSDate *)dateProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef {
    CFDateRef dateRef = (ABRecordCopyValue(recordRef, property));
    return (__bridge_transfer NSDate *)dateRef;
}

- (NSArray *)arrayOfphonesWithTagsFromRecord:(ABRecordRef)recordRef {
    __block NSMutableArray *array = [[NSMutableArray alloc] init];
    [self enumerateMultiValueOfProperty:kABPersonPhoneProperty fromRecord:recordRef
                              withBlock:^(ABMultiValueRef multiValue, NSUInteger index){
                                  CFTypeRef rawPhone = ABMultiValueCopyValueAtIndex(multiValue, index);
                                  NSString *phone = (__bridge_transfer NSString *)rawPhone;
                                  if (phone){
                                      NSString *originalTag = [self originalTagFromMultiValue:multiValue index:index];
                                      NSString *localizedTag = [self localizedTagFromMultiValue:multiValue index:index];
                                      CFXABPhoneWithTag *phoneWithLabel = [[CFXABPhoneWithTag alloc] initWithPhone:phone originalTag:originalTag
                                                                                                      localizedTag:localizedTag];
                                      [array addObject:phoneWithLabel];
                                  }
                              }];
    return array.copy;
}

- (UIImage *)imagePropertyFullSize:(BOOL)isFullSize fromRecord:(ABRecordRef)recordRef {
    ABPersonImageFormat format = isFullSize ? kABPersonImageFormatOriginalSize :
    kABPersonImageFormatThumbnail;
    NSData *data = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(recordRef, format);
    return [UIImage imageWithData:data scale:UIScreen.mainScreen.scale];
}

- (NSString *)originalTagFromMultiValue:(ABMultiValueRef)multiValue index:(NSUInteger)index {
    NSString *label;
    CFTypeRef rawLabel = ABMultiValueCopyLabelAtIndex(multiValue, index);
    label = (__bridge_transfer NSString *)rawLabel;
    return label;
}

- (NSString *)localizedTagFromMultiValue:(ABMultiValueRef)multiValue index:(NSUInteger)index {
    NSString *label;
    CFTypeRef rawLabel = ABMultiValueCopyLabelAtIndex(multiValue, index);
    if (rawLabel){
        CFStringRef localizedTag = ABAddressBookCopyLocalizedLabel(rawLabel);
        if (localizedTag){
            label = (__bridge_transfer NSString *)localizedTag;
        }
        
        if (rawLabel) {
            CFRelease(rawLabel);
        }
    }
    return label;
}

- (NSString *)compositeNameFromRecord:(ABRecordRef)recordRef {
    CFStringRef compositeNameRef = ABRecordCopyCompositeName(recordRef);
    return (__bridge_transfer NSString *)compositeNameRef;
}

- (void)enumerateMultiValueOfProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef
                            withBlock:(void (^)(ABMultiValueRef multiValue, NSUInteger index))block {
    ABMultiValueRef multiValue = ABRecordCopyValue(recordRef, property);
    if (multiValue){
        NSUInteger count = (NSUInteger)ABMultiValueGetCount(multiValue);
        for (NSUInteger i = 0; i < count; i++){
            block(multiValue, i);
        }
        
        if (multiValue) {
            CFRelease(multiValue);
        }
    }
}

@end
