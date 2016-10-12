# CPContact

[![CI Status](http://img.shields.io/travis/xiaochengfei/CPContact.svg?style=flat)](https://travis-ci.org/xiaochengfei/CPContact)
[![Version](https://img.shields.io/cocoapods/v/CPContact.svg?style=flat)](http://cocoapods.org/pods/CPContact)
[![License](https://img.shields.io/cocoapods/l/CPContact.svg?style=flat)](http://cocoapods.org/pods/CPContact)
[![Platform](https://img.shields.io/cocoapods/p/CPContact.svg?style=flat)](http://cocoapods.org/pods/CPContact)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS8+

## Installation

CPContact is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CPContact"
```

## Guide

The following code is just for test. Take it easy.😄 

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


## TODO
ABAddressBook is deprecated on iOS9, so i will use CNContact instead.

## Author

CrespoXiao <http://weibo.com/crespoxiao>

## License

CPContact is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
