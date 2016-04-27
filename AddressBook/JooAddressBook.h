//
//  JooAddressBook.h



#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>



AB_EXTERN const ABPropertyID kABPersonHeadImageProperty;//头像

@interface JooAddressBook : NSObject

#pragma  mark  添加联系人-- 联系人名称、号码、号码备注标签
+ (BOOL)addContactWithName:(NSString*)name phone:(NSString*)phone label:(NSString*)label  refusedAccessBlock:(void (^)(void))refusedAccessBlock;

#pragma mark 查找通讯录中是否有这个手机号
+ (BOOL)isContactExistByPhone:(NSString*)phone refusedAccessBlock:(void (^)(void))refusedAccessBlock;

#pragma mark 获取通讯录内容
//searchKeys 要检索的内容，如kABPersonFirstNameProperty等
+ (NSArray<NSDictionary *> *)getAllContacts:(ABPropertyID *)searchKeys
                                 keysCount:(const int) keysCount
                             progressBlock:(void (^)(const int total,const int current))progressBlock
                        refusedAccessBlock:(void (^)(void))refusedAccessBlock;

@end
