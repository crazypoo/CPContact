//
//  CFXContact.h
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import <Foundation/Foundation.h>
#import "CFXABContactModel.h"

@interface CFXContact : NSObject

+ (void)loadContacts:(void(^)(NSArray * array))block;

+ (void)addReocrdWithModel:(CFXABContactModel *)contactModel success:(void(^)(BOOL success))block;

+ (void)addPhoneNumber:(NSString *)displayNum toExistFullName:(NSString *)name success:(void(^)(BOOL success))block;

+ (void)removedRecordWithFullName:(NSString *)fullName success:(void(^)(BOOL success))block;;

+ (void)delAllRecord:(void(^)(BOOL success))block;;

@end
