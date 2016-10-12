//
//  CFXAddressBook.m
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import "CFXAddressBook.h"

void CFXABAddressBookExternalChangeCallback(ABAddressBookRef addressBookRef, CFDictionaryRef info, void *context);

@interface CFXAddressBook ()

@property (atomic, readonly) ABAddressBookRef addressBook;
@property (nonatomic, copy ) void (^changeCallback)();

@end

@implementation CFXAddressBook

#pragma mark - life cycle

- (id)init {
    self = [super init];
    if (self){
        self.fieldsMask = CFXABContactFieldDefault;
        CFErrorRef *error = NULL;
        _addressBook = ABAddressBookCreateWithOptions(NULL, error);
        if (error){
            NSString *errorReason = (__bridge_transfer NSString *)CFErrorCopyFailureReason(*error);
            NSLog(@"create addressbook failed");
        }
    }
    return self;
}

- (void)dealloc {
    [self stopObserveChanges];
    if (_addressBook){
        CFRelease(_addressBook);
    }
}

#pragma mark - public

+ (CFXABAccess)access {
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    switch (status){
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted:
            return CFXABAccessDenied;
            
        case kABAuthorizationStatusAuthorized:
            return CFXABAccessGranted;
            
        default:
            return CFXABAccessUnknown;
    }
}

+ (void)requestAccess:(void (^)(BOOL granted, NSError * error))completionBlock {
    [self requestAccessOnQueue:dispatch_get_main_queue() completion:completionBlock];
}

+ (void)requestAccessOnQueue:(dispatch_queue_t)queue
                  completion:(void (^)(BOOL granted, NSError * error))completionBlock {
    CFErrorRef *initializationError = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, initializationError);
    if (initializationError){
        completionBlock ? completionBlock(NO, (__bridge NSError *)(*initializationError)) : nil;
    } else {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
            dispatch_async(queue, ^{
                completionBlock ? completionBlock(granted, (__bridge NSError *)error) : nil;
            });
        });
    }
    
}

- (void)loadContacts:(void (^)(NSArray *contacts, NSError *error))completionBlock {
    [self loadContactsOnQueue:dispatch_get_main_queue() completion:completionBlock];
}

- (void)loadContactsOnQueue:(dispatch_queue_t)queue
                 completion:(void (^)(NSArray *contacts, NSError *error))completionBlock {
    CFXABContactField fieldMask = self.fieldsMask;
    NSArray *descriptors = self.sortDescriptors;
    CFXABContactFilterBlock filterBlock = self.filterBlock;
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef errorRef) {
        NSArray *array = nil;
        NSError *error = nil;
        if (granted){
            __block CFArrayRef peopleArrayRef;
            peopleArrayRef = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
            NSUInteger contactCount = (NSUInteger)CFArrayGetCount(peopleArrayRef);
            NSMutableArray *contacts = [[NSMutableArray alloc] init];
            for (NSUInteger i = 0; i < contactCount; i++) {
                ABRecordRef recordRef = CFArrayGetValueAtIndex(peopleArrayRef, i);
                CFXABContact *contact = [[CFXABContact alloc] initWithRecordRef:(__bridge ABRecordRef)((__bridge id)(recordRef))
                                                                    fieldMask:fieldMask];
                if (!filterBlock || filterBlock(contact)) {
                    [contacts addObject:contact];
                }
            }
            [contacts sortUsingDescriptors:descriptors];
            array = contacts.copy;
            
            if (peopleArrayRef) {
                CFRelease(peopleArrayRef);
            }
        }
        error = errorRef ? (__bridge NSError *)errorRef : nil;
        dispatch_async(queue, ^{
            completionBlock ? completionBlock(array, error) : nil;
        });
    });
}

- (void)startObserveChangesWithCallback:(void (^)())callback {
    if (callback){
        if (!self.changeCallback){
            ABAddressBookRegisterExternalChangeCallback(self.addressBook,
                                                        CFXABAddressBookExternalChangeCallback,
                                                        (__bridge void *)(self));
        }
        self.changeCallback = callback;
    }
}

- (void)stopObserveChanges {
    if (self.changeCallback){
        self.changeCallback = nil;
        ABAddressBookUnregisterExternalChangeCallback(self.addressBook,
                                                      CFXABAddressBookExternalChangeCallback,
                                                      (__bridge void *)(self));
    }
}

- (CFXABContact *)getContactByRecordID:(NSNumber *)recordID {
    CFXABContact *contact = nil;
    ABRecordRef ref = ABAddressBookGetPersonWithRecordID(self.addressBook, recordID.intValue);
    if (ref != NULL){
        contact = [[CFXABContact alloc] initWithRecordRef:(__bridge ABRecordRef)((__bridge id)(ref)) fieldMask:self.fieldsMask];
    }
    return contact;
}

#pragma mark - external change callback

void CFXABAddressBookExternalChangeCallback(ABAddressBookRef __unused addressBookRef,
                                           CFDictionaryRef __unused info,
                                           void *context) {
    ABAddressBookRevert(addressBookRef);
    CFXAddressBook *addressBook = (__bridge CFXAddressBook *)(context);
    addressBook.changeCallback ? addressBook.changeCallback() : nil;
}

@end
