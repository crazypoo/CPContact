//
//  CFXAddressBook.h
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import <Foundation/Foundation.h>
#import "CFXABContact.h"

@class CFXABContact;

@interface CFXAddressBook : NSObject

@property (nonatomic, assign) CFXABContactField       fieldsMask;
@property (nonatomic, copy  ) CFXABContactFilterBlock filterBlock;
@property (nonatomic, strong) NSArray                 *sortDescriptors;

+ (CFXABAccess)access;
+ (void)requestAccess:(void (^)(BOOL granted, NSError * error))completionBlock;
+ (void)requestAccessOnQueue:(dispatch_queue_t)queue
                  completion:(void (^)(BOOL granted, NSError * error))completionBlock;

- (void)loadContacts:(void (^)(NSArray *contacts, NSError *error))completionBlock;
- (void)loadContactsOnQueue:(dispatch_queue_t)queue
                 completion:(void (^)(NSArray *contacts, NSError *error))completionBlock;

- (void)startObserveChangesWithCallback:(void (^)())callback;
- (void)stopObserveChanges;

- (CFXABContact *)getContactByRecordID:(NSNumber *)recordID;

@end
