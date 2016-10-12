//
//  CFXViewController.m
//  CPContact
//
//  Created by xiaochengfei on 10/12/2016.
//  Copyright (c) 2016 xiaochengfei. All rights reserved.
//

#import "CFXViewController.h"
#import <CPContact/CFXContact.h>

@interface CFXViewController ()

@end

@implementation CFXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    CFXABContactModel *model = [[CFXABContactModel alloc]init];
    model.basicModel = [[CFXABBasicInfoModel alloc]init];
    model.basicModel.firstName = @"xiao";
    model.basicModel.lastName = @"crespo";
    model.basicModel.title = @"ceo";
    CFXABPhoneModel *phone = [[CFXABPhoneModel alloc]init];
    phone.number = @"1111";
    phone.type = @"office";
    model.phoneArray = @[phone];
    [CFXContact addReocrdWithModel:model success:^(BOOL success) {
        NSLog(@"test1: %d",success);
        
        [CFXContact addPhoneNumber:@"2222" toExistFullName:@"xiao crespo" success:^(BOOL success) {
            NSLog(@"test2: %d",success);
            
            [CFXContact loadContacts:^(NSArray *array) {
                NSLog(@"test3: %lu",(unsigned long)[array count]);
                
                [CFXContact removedRecordWithFullName:@"xiao crespo" success:^(BOOL success) {
                    NSLog(@"test4: %d",success);
                    
                    [CFXContact loadContacts:^(NSArray *array) {
                        NSLog(@"test5: %lu",(unsigned long)[array count]);
                        
                        [CFXContact delAllRecord:^(BOOL success) {
                            NSLog(@"test6: %d",success);
                            
                            [CFXContact loadContacts:^(NSArray *array) {
                                NSLog(@"test7: %lu",(unsigned long)[array count]);
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
