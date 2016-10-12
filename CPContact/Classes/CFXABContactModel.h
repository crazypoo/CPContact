//
//  CFXABContactModel.h
//  Pods
//
//  Created by xiaochengfei on 16/10/12.
//
//

#import <Foundation/Foundation.h>

@class CFXABBasicInfoModel,CFXABPhoneModel,CFXABEmailModel,CFXABAddressModel;

@interface CFXABContactModel : NSObject

@property (nonatomic,strong) NSString            * homePageurl;
@property (nonatomic,strong) CFXABBasicInfoModel * basicModel;
@property (nonatomic,strong) NSArray             * phoneArray;
@property (nonatomic,strong) NSArray             * emailArray;
@property (nonatomic,strong) CFXABAddressModel   * addressModel;

@end


@interface CFXABBasicInfoModel : NSObject

@property(nonatomic,strong)NSString * firstName;
@property(nonatomic,strong)NSString * lastName;
@property(nonatomic,strong)NSString * title;
@property(nonatomic,strong)NSString * department;
@property(nonatomic,strong)NSString * orgnize;
@property(nonatomic,strong)NSString * note;

@end


@interface CFXABPhoneModel : NSObject

@property(nonatomic,strong)NSString * number;
@property(nonatomic,strong)NSString * type;

@end


@interface CFXABEmailModel :NSObject

@property(nonatomic,strong)NSString  * detail;
@property(nonatomic,strong)NSString  * type;

@end


@interface CFXABAddressModel : NSObject

@property(nonatomic,strong)NSString  *street;
@property(nonatomic,strong)NSString  *city;
@property(nonatomic,strong)NSString  *zip;
@property(nonatomic,strong)NSString  *country;
@property(nonatomic,strong)NSString  *countryCode;

@end
