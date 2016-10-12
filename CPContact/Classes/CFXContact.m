//
//  CFXContact.m
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import "CFXContact.h"
#import "CFXAddressBook.h"
#import "CFXABProfile.h"


#ifdef DEBUG
#   define  CFXLog(fmt, ...)       NSLog((@"[CFXContact][%s][Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define  CFXLog(...)
#endif

#define CFXSafeBlock(block, ...)   block ? block(__VA_ARGS__) : nil


static dispatch_semaphore_t _globalLock;


@implementation CFXContact

#pragma mark - load addres book

+ (void)loadContacts:(void(^)(NSArray * array))block {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            // First time access has been granted
            if (granted) {
                [CFXContact loadContacts_internal:^(NSArray *array, NSError *error) {
                    CFXSafeBlock(block,array);
                }];
            } else {
                CFXSafeBlock(block,nil);
            }
            if (addressBookRef) {
                CFRelease(addressBookRef);
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access
        [CFXContact loadContacts_internal:^(NSArray *array, NSError *error) {
            CFXSafeBlock(block,array);
        }];
    } else {
        CFXSafeBlock(block,nil);
    }
}

+ (void)loadContacts_internal:(void(^)(NSArray * array,NSError * error))block {
    
    CFXAddressBook *addressBook = [[CFXAddressBook alloc] init];
    [addressBook startObserveChangesWithCallback:^{
         CFXLog(@"address book changed");
    }];
    addressBook.fieldsMask = CFXABContactFieldAll;
    addressBook.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
    addressBook.filterBlock = ^BOOL(CFXABContact *contact){
        return contact.phones.count > 0;
    };
    [addressBook loadContacts:^(NSArray *contacts, NSError *error){
        if (!error){
             CFXLog(@"%@",contacts);
             CFXSafeBlock(block,contacts,nil);
        } else {
             CFXLog(@"%@",error.localizedDescription);
             CFXSafeBlock(block,nil,error);
        }
    }];
}

#pragma mark - add a record to address book

+ (void)addReocrdWithModel:(CFXABContactModel *)contactModel success:(void(^)(BOOL success))block {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [CFXContact addReocrd_internal:contactModel];
                CFXSafeBlock(block,granted);
            } else {
                CFXSafeBlock(block,NO);
            }
            if (addressBookRef) {
                CFRelease(addressBookRef);
            }
            
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [CFXContact addReocrd_internal:contactModel];
        CFXSafeBlock(block,YES);
    } else {
        CFXSafeBlock(block,NO);
    }
}

+ (void)addReocrd_internal:(CFXABContactModel *)contactModel {
    
    //delete if already exist
    if (contactModel.basicModel.lastName) {
        [CFXContact removedRecordFromAddressBookWithFirstValue_internal:contactModel.basicModel.lastName];
    }
    [[self class] lock];
    // Creating new entry
    ABAddressBookRef m_addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABPersonCreate();
    // Setting basic properties
    if (contactModel.basicModel) {
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(contactModel.basicModel.firstName?:@"") , nil);
        ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(contactModel.basicModel.lastName?:@""), nil);
        ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFTypeRef)(contactModel.basicModel.title?:@""), nil);
        ABRecordSetValue(person, kABPersonDepartmentProperty, (__bridge CFTypeRef)(contactModel.basicModel.department?:@""), nil);
        ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFTypeRef)(contactModel.basicModel.orgnize?:@""), nil);
        ABRecordSetValue(person, kABPersonNoteProperty, (__bridge CFTypeRef)(contactModel.basicModel.note?:@""), nil);
    }
    // Adding phone numbers
    if (contactModel.phoneArray && [contactModel.phoneArray count]) {
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (CFXABPhoneModel *item in contactModel.phoneArray) {
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(item.number?:@""), (__bridge CFStringRef)(item.type?:@""), NULL);
        }
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
        if (phoneNumberMultiValue) {
            CFRelease(phoneNumberMultiValue);
        }
    }
    // Adding url
    if (contactModel.homePageurl) {
        ABMutableMultiValueRef urlMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(urlMultiValue, (__bridge CFTypeRef)(contactModel.homePageurl?:@""), kABPersonHomePageLabel, NULL);
        ABRecordSetValue(person, kABPersonURLProperty, urlMultiValue, nil);
        if (urlMultiValue) {
            CFRelease(urlMultiValue);
        }
    }
    // Adding emails
    if (contactModel.emailArray && [contactModel.emailArray count]) {
        ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (CFXABEmailModel *item in contactModel.emailArray) {
            ABMultiValueAddValueAndLabel(emailMultiValue, (__bridge CFTypeRef)(item.detail?:@""), (__bridge CFStringRef)(item.type?:@""), NULL);
        }
        ABRecordSetValue(person, kABPersonURLProperty, emailMultiValue, nil);
        if (emailMultiValue) {
            CFRelease(emailMultiValue);
        }
    }
    // Adding address
    if (contactModel.addressModel) {
        ABMutableMultiValueRef addressMultipleValue = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
        [addressDictionary setObject:contactModel.addressModel.street?:@"" forKey:(NSString *)kABPersonAddressStreetKey];
        [addressDictionary setObject:contactModel.addressModel.city?:@"" forKey:(NSString *)kABPersonAddressCityKey];
        [addressDictionary setObject:contactModel.addressModel.zip?:@"" forKey:(NSString *)kABPersonAddressZIPKey];
        [addressDictionary setObject:contactModel.addressModel.country?:@"" forKey:(NSString *)kABPersonAddressCountryKey];
        [addressDictionary setObject:contactModel.addressModel.countryCode?:@"" forKey:(NSString *)kABPersonAddressCountryCodeKey];
        ABMultiValueAddValueAndLabel(addressMultipleValue, (__bridge CFTypeRef)(addressDictionary), kABHomeLabel, NULL);
        ABRecordSetValue(person, kABPersonAddressProperty, addressMultipleValue, nil);
        
        if (addressMultipleValue) {
            CFRelease(addressMultipleValue);
        }
    }
    // Adding person to the address book
    CFErrorRef error=NULL;
    ABAddressBookAddRecord(m_addressBook, person, nil);
    ABAddressBookSave(m_addressBook,&error);
    
    if (person) {
        CFRelease(person);
    }
    if (m_addressBook) {
        CFRelease(m_addressBook);
    }
    [[self class] unlock];
}

#pragma mark - add a number

+ (void)addPhoneNumber:(NSString *)displayNum toExistFullName:(NSString *)name success:(void (^)(BOOL))block {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            // First time access has been granted, add the contact
            if (granted) {
                [CFXContact addPhoneNumber_internal:displayNum name:name success:^(BOOL success) {
                    CFXSafeBlock(block,success);
                }];
            } else {
                CFXSafeBlock(block,NO);
            }
            if (addressBookRef) {
                CFRelease(addressBookRef);
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [CFXContact addPhoneNumber_internal:displayNum name:name success:^(BOOL success) {
            CFXSafeBlock(block,success);
        }];
    } else {
        CFXSafeBlock(block,NO);
    }
}

+ (void)addPhoneNumber_internal:(NSString *)displayNum name:(NSString *)name success:(void(^)(BOOL success))block {
    
    __block BOOL alreadySaved = NO;
    [CFXContact loadContacts:^(NSArray *array) {
        if (array && [array count]) {
            [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[CFXABContact class]]) {
                    CFXABContact *item = (CFXABContact*)obj;
                    if ([item.firstName hasPrefix:name] || [item.lastName hasPrefix:name] ||
                        [item.middleName hasPrefix:name] || [item.compositeName hasPrefix:name] ||
                        [item.company hasPrefix:name]) {
                        *stop = YES;
                        
                        [item.phonesWithTags enumerateObjectsUsingBlock:^(id  _Nonnull obj_inner, NSUInteger idx_inner, BOOL * _Nonnull stop_inner) {
                            if ([obj_inner isKindOfClass:[CFXABPhoneWithTag class]]) {
                                CFXABPhoneWithTag *phoneItem = (CFXABPhoneWithTag *)obj_inner;
                                if ([phoneItem.phone isEqualToString:displayNum]) {
                                    *stop_inner = alreadySaved = YES;
                                    CFXSafeBlock(block,alreadySaved);
                                }
                            }
                            if ((idx_inner == [item.phonesWithTags count]-1) && !alreadySaved) {
                                CFXLog(@"number dosen't exist, save to addressbook");
                                CFErrorRef err;
                                ABAddressBookRef m_addressBook= ABAddressBookCreateWithOptions(NULL,&err);
                                CFArrayRef people=ABAddressBookCopyArrayOfAllPeople(m_addressBook);
                                CFIndex nPeople=ABAddressBookGetPersonCount(m_addressBook);
                                NSString *currRecordFullName;
                                /*Invariant: No record with the name fullName has been
                                 found so far.*/
                                for(NSInteger i=0;i<nPeople;i++){
                                    ABRecordRef ref=CFArrayGetValueAtIndex(people,i);
                                    CFErrorRef error=NULL;
                                    currRecordFullName = (__bridge_transfer NSString *)(ABRecordCopyCompositeName(ref));
                                    if([currRecordFullName isEqualToString:name]){
                                        //copy record,insert a number and save
                                        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                                        
                                        for (CFXABPhoneWithTag *phone_item in item.phonesWithTags) {
                                            ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(phone_item.phone?:@""), (__bridge CFStringRef)(@""), NULL);
                                        }
                                        
                                        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(displayNum), (__bridge CFStringRef)(@""), NULL);
                                        ABRecordSetValue(ref, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
                                        ABAddressBookAddRecord(m_addressBook, ref, nil);
                                        ABAddressBookSave(m_addressBook,&error);
                                        
                                        if (phoneNumberMultiValue) {
                                            CFRelease(phoneNumberMultiValue);
                                        }
                                        if(error!=NULL){
                                            CFStringRef errorDesc=CFErrorCopyDescription(error);
                                            CFXLog(@"Failed to add record: %@",errorDesc);
                                            CFXSafeBlock(block,NO);
                                            if (errorDesc) {
                                                CFRelease(errorDesc);
                                            }
                                        } else {
                                            CFXLog(@"Record added");
                                            CFXSafeBlock(block,YES);
                                        }
                                        break;
                                    }
                                }
                                if (m_addressBook) {
                                    CFRelease(m_addressBook);
                                }
                                if (people) {
                                    CFRelease(people);
                                }
                            }
                        }];
                    }
                }
            }];
        }
    }];
}

#pragma mark - delete an address record

+ (void)removedRecordWithFullName:(NSString *)fullName success:(void (^)(BOOL))block {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                CFXSafeBlock(block,[CFXContact removedRecordFromAddressBookWithFirstValue_internal:fullName]);
            } else {
                CFXSafeBlock(block,NO);
            }
            if (addressBookRef) {
                CFRelease(addressBookRef);
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        CFXSafeBlock(block,[CFXContact removedRecordFromAddressBookWithFirstValue_internal:fullName]);
    } else {
        CFXSafeBlock(block,NO);
    }
}

+ (BOOL)removedRecordFromAddressBookWithFirstValue_internal:(NSString *)fullName {
    
    [[self class] lock];
    BOOL recordRemoved = NO;
    if (!fullName || (fullName && ![fullName length])) {
        [[self class] unlock];
        return recordRemoved;
    }
    CFErrorRef err;
    ABAddressBookRef m_addressBook = ABAddressBookCreateWithOptions(NULL,&err);
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(m_addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(m_addressBook);
    
    if (!people || (people && ![(__bridge NSArray *)people count]) || nPeople > [(__bridge NSArray *)people count]) {
        if (people) {
            CFRelease(people);
        }
        if (m_addressBook) {
            CFRelease(m_addressBook);
        }
        [[self class] unlock];
        return recordRemoved;
    }
    
    NSString *currRecordFullName;
    CFErrorRef error;
    for(NSInteger i = 0;i < nPeople; i++){
        ABRecordRef ref = CFArrayGetValueAtIndex(people,i);
        currRecordFullName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(ref);
        if([currRecordFullName isEqualToString:fullName]){
            ABAddressBookRemoveRecord(m_addressBook,ref,&error);
            ABAddressBookSave(m_addressBook,&error);
            if(error==NULL){
                 CFXLog(@"Record removed");
                recordRemoved=YES;
            }
            break;
        }
    }
    
    if (people) {
        CFRelease(people);
    }
    if (m_addressBook) {
        CFRelease(m_addressBook);
    }
    [[self class] unlock];
    return recordRemoved;
}

#pragma mark - delete all address record

+ (void)delAllRecord:(void (^)(BOOL))block {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                CFXSafeBlock(block,[CFXContact delAllRecord_internal]);
            } else {
                CFXSafeBlock(block,NO);
            }
            if (addressBookRef) {
                CFRelease(addressBookRef);
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        CFXSafeBlock(block,[CFXContact delAllRecord_internal]);
    } else {
        CFXSafeBlock(block,NO);
    }
}

+ (BOOL)delAllRecord_internal {
    
    [[self class] lock];
    BOOL delSucceed = NO;
    ABAddressBookRef m_addressBook = CFBridgingRetain((__bridge id)(ABAddressBookCreateWithOptions(NULL, NULL)));
    CFIndex count = ABAddressBookGetPersonCount(m_addressBook);
    if(count==0 && m_addressBook!=NULL) { //If there are no contacts, don't delete
        if (m_addressBook) {
            CFRelease(m_addressBook);
        }
        [[self class] unlock];
        return delSucceed;
    }
    //Get all contacts and store it in a CFArrayRef
    CFArrayRef theArray = ABAddressBookCopyArrayOfAllPeople(m_addressBook);
    for(CFIndex i=0;i<count;i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(theArray, i); //Get the ABRecord
        BOOL result = ABAddressBookRemoveRecord (m_addressBook,person,NULL); //remove it
        if(result) { //if successful removal
            BOOL save = ABAddressBookSave(m_addressBook, NULL); //save address book state
            if(save && person!=NULL) {
                delSucceed = YES;
            } else {
                person = nil;
                 CFXLog(@"Couldn't save, breaking out");
                break;
            }
        } else {
            person = nil;
             CFXLog(@"Couldn't delete, breaking out");
            break;
        }
        person = nil;
    }
    if(m_addressBook) {
        CFRelease(m_addressBook);
    }
    if (theArray) {
        CFRelease(theArray);
    }
    [[self class]unlock];
    return delSucceed;
}

#pragma mark - lock methods

+ (void)lock {
    if (!_globalLock) {
        _globalLock = dispatch_semaphore_create(1);
    }
    dispatch_semaphore_wait(_globalLock, DISPATCH_TIME_FOREVER);
}

+ (void)unlock {
    if (_globalLock) {
        dispatch_semaphore_signal(_globalLock);
    }
}


@end
