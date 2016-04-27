//
//  JooAddressBook.m

//

#import "JooAddressBook.h"


const ABPropertyID kABPersonHeadImageProperty = 1234;


@implementation JooAddressBook

+(void)initialize
{
    if(self == [JooAddressBook class])
    {
        CFRelease(ABPersonCreate());//
    }
    
}



#pragma  mark 添加联系人
// 添加联系人（联系人名称、号码、号码备注标签）
+ (BOOL)addContactWithName:(NSString*)name phone:(NSString*)phone label:(NSString*)label  refusedAccessBlock:(void (^)(void))refusedAccessBlock
{
    // 创建一条空的联系人
    ABRecordRef record = ABPersonCreate();
    CFErrorRef error;
    // 设置联系人的名字
    ABRecordSetValue(record, kABPersonFirstNameProperty, (CFTypeRef)name, &error);
    // 添加联系人电话号码以及该号码对应的标签名
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    ABMultiValueAddValueAndLabel(multi, ( CFTypeRef)phone, ( CFTypeRef)label, NULL);
    ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
    ABAddressBookRef addressBook = nil;
    // 如果为iOS6以上系统，需要等待用户确认是否允许访问通讯录。
    
    __block BOOL isGranted = TRUE;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     isGranted = isGranted;
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    BOOL success = FALSE;
    if(!isGranted && refusedAccessBlock)
    {
        refusedAccessBlock();//
    }
    else
    {
        // 将新建联系人记录添加如通讯录中
        success = ABAddressBookAddRecord(addressBook, record, &error);
        if (success)
        {
            // 如果添加记录成功，保存更新到通讯录数据库中
            success = ABAddressBookSave(addressBook, &error);
        }
    }
    
    if(record) CFRelease(record);
    if(addressBook) CFRelease(addressBook);
    CFRelease(multi);
    return success;
}
#pragma  mark 指定号码是否已经存在
+ (BOOL)isContactExistByPhone:(NSString*)phone refusedAccessBlock:(void (^)(void))refusedAccessBlock
{
    ABAddressBookRef addressBook = nil;
    __block BOOL isGranted = TRUE;
    BOOL result = FALSE;
    //
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     isGranted = granted;
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    if(!isGranted && refusedAccessBlock)
    {
        refusedAccessBlock();
    }
    else
    {
        CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
        // 遍历全部联系人，检查是否存在指定号码
        for (int i=0; i<CFArrayGetCount(records); i++)
        {
            ABRecordRef record = CFArrayGetValueAtIndex(records, i);
            CFTypeRef items = ABRecordCopyValue(record, kABPersonPhoneProperty);
            CFArrayRef phoneNums = ABMultiValueCopyArrayOfAllValues(items);
            if (phoneNums)
            {
                for (int j=0; j<CFArrayGetCount(phoneNums); j++)
                {
                    NSString *phone = (NSString*)CFArrayGetValueAtIndex(phoneNums, j);
                    if ([phone isEqualToString:phone])
                    {
                        result = TRUE;
                        break;
                    }
                }//for
            }//fi
            if(result)//已经找到
            {
                break;
            }
        }//for
        CFRelease(records);
    }
    
    if(addressBook) CFRelease(addressBook);
    return result;
}
#pragma mark 获取通讯录内容

+ (NSArray<NSDictionary *> *)getAllContacts:(ABPropertyID *)searchKeys
                                 keysCount:(const int) keysCount
                             progressBlock:(void (^)(const int,const int))progressBlock
                        refusedAccessBlock:(void (^)(void))refusedAccessBlock

{
    if(!searchKeys || keysCount <= 0)
    {
        return nil;
    }
    
    NSMutableArray * dataArray = [NSMutableArray array];
    //取得本地通信录名柄
    ABAddressBookRef addressBook ;
    __block BOOL isGranted = FALSE;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     isGranted = granted;
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    
    if(!isGranted && refusedAccessBlock)
    {
        refusedAccessBlock();
    }
    else
    {
        //取得本地所有联系人记录
        CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBook);
        int resultCount = CFArrayGetCount(results);
        for(int i = 0; i < resultCount; i++)
        {
            NSMutableDictionary *dicInfoLocal = [NSMutableDictionary dictionary];
            ABRecordRef person = CFArrayGetValueAtIndex(results, i);
            
            for(int j = 0;j < keysCount;j++)
            {
                ABPropertyID pid = searchKeys[j];
                id value = 0;
                if(pid == kABPersonEmailProperty)
                {
                    value = [self getEmailsCopy:person];
                }
                else if (pid == kABPersonAddressProperty)
                {
                    value = [self getAddressesCopy:person];
                }
                else if (pid == kABPersonDateProperty ||
                         pid == kABPersonCreationDateProperty ||
                         pid == kABPersonModificationDateProperty)
                {
                    value = [self getDatesCopy:person];
                }
                else if (pid == kABPersonInstantMessageProperty)
                {
                    value = [self getIMsCopy:person];
                }
                else if (pid == kABPersonPhoneProperty)
                {
                    value = [self getPhonesCopy:person];
                }
                else if (pid == kABPersonURLProperty)
                {
                    value = [self getURLsCopy:person];
                }
                else if (pid == kABPersonRelatedNamesProperty)
                {
                    value = [self getRelatedNamesCopy:person];
                }
                else if (pid == kABPersonHeadImageProperty)
                {
                    value = (NSData*)ABPersonCopyImageData(person);
                }
                else
                {
                    value = (id)ABRecordCopyValue(person, pid);
                }
                
                
                if(value)
                {
                    [dicInfoLocal setObject:value forKey:[NSNumber numberWithInt:pid]];
                    [value release];//need release
                }
                
            }//for
            
            [dataArray addObject:dicInfoLocal];//
            if(progressBlock)
            {
                progressBlock(resultCount,i + 1);
            }
        }//for
        CFRelease(results);//new
    }
    
    if(addressBook) CFRelease(addressBook);
    
    return [dataArray copy];

}

+ (NSArray<NSDictionary*> *)getEmailsCopy:(ABRecordRef)person
{
    //获取email多值
    NSMutableArray * array = [NSMutableArray array];
    
    ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
    int emailcount = ABMultiValueGetCount(email);
    for (int x = 0; x < emailcount; x++)
    {
        //获取email Label
        NSString* emailLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(email, x));
        //获取email值
        NSString* emailContent = (NSString*)ABMultiValueCopyValueAtIndex(email, x);
        
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(emailLabel) dic[@"label"] = emailLabel;
        if(emailContent) dic[@"content"] = emailContent;
        
        [emailLabel release];
        [emailContent release];
        
        [array addObject:dic];
    }
    CFRelease(email);
    
    return [[array copy] retain];
}
+ (NSArray<NSDictionary *> *)getAddressesCopy:(ABRecordRef)person
{
    //读取地址多值
    NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);
    int count = ABMultiValueGetCount(address);
    for(int j = 0; j < count; j++)
    {
        //获取地址Label
        NSString* addressLabel = (NSString*)ABMultiValueCopyLabelAtIndex(address, j);
        //获取該label下的地址6属性
        NSDictionary* personaddress =(NSDictionary*) ABMultiValueCopyValueAtIndex(address, j);
        
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(addressLabel) dic[@"label"] = addressLabel;
        if(personaddress) dic[@"content"] = personaddress;
        
        CFRelease(addressLabel);
        CFRelease(personaddress);
        
        [array addObject:dic];
    }
    CFRelease(address);
    return [[array copy] retain];

}

+ (NSArray<NSDictionary *> *)getDatesCopy:(ABRecordRef)person
{
    //获取dates多值
     NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef dates = ABRecordCopyValue(person, kABPersonDateProperty);
    int datescount = ABMultiValueGetCount(dates);
    for (int y = 0; y < datescount; y++)
    {
        //获取dates Label
        NSString* datesLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(dates, y));
        //获取dates值
        NSString* datesContent = (NSString*)ABMultiValueCopyValueAtIndex(dates, y);
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(datesLabel) dic[@"label"] = datesLabel;
        if(datesContent) dic[@"content"] = datesContent;
        [datesLabel release];
        [datesContent release];
        
        [array addObject:dic];
    }
    CFRelease(dates);
    return [[array copy] retain];

}

+ (NSArray<NSDictionary *> *)getIMsCopy:(ABRecordRef)person
{
    //获取IM多值
    NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef instantMessage = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
    for (int l = 1; l < ABMultiValueGetCount(instantMessage); l++)
    {
        //获取IM Label
        NSString* instantMessageLabel = (NSString*)ABMultiValueCopyLabelAtIndex(instantMessage, l);
        //获取該label下的2属性
        NSDictionary* instantMessageContent =(NSDictionary*) ABMultiValueCopyValueAtIndex(instantMessage, l);
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(instantMessageLabel) dic[@"label"] = instantMessageLabel;
        if(instantMessageContent) dic[@"content"] = instantMessageContent;
        
        CFRelease(instantMessageLabel);
        CFRelease(instantMessageContent);
        
        [array addObject:dic];
    }
    
    CFRelease(instantMessage);
    return [[array copy] retain];

}
+ (NSArray<NSDictionary *> *)getPhonesCopy:(ABRecordRef)person
{
    //读取电话多值
    NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int k = 0; k<ABMultiValueGetCount(phone); k++)
    {
        //获取电话Label
        NSString * personPhoneLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phone, k));
        //获取該Label下的电话值
        NSString * personPhone = (NSString*)ABMultiValueCopyValueAtIndex(phone, k);
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(personPhoneLabel) dic[@"label"] = personPhoneLabel;
        if(personPhone) dic[@"content"] = personPhone;
        
        CFRelease(personPhoneLabel);
        CFRelease(personPhone);
        [array addObject:dic];
    }
    CFRelease(phone);
    return [[array copy] retain];
}
+ (NSArray<NSDictionary *> *)getRelatedNamesCopy:(ABRecordRef)person
{
    NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef phone = ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
    for (int k = 0; k<ABMultiValueGetCount(phone); k++)
    {
        NSString * label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phone, k));
        NSString * content = (NSString*)ABMultiValueCopyValueAtIndex(phone, k);
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(label) dic[@"label"] = label;
        if(content) dic[@"content"] = content;
        CFRelease(label);
        CFRelease(content);
        
        [array addObject:dic];
    }
    CFRelease(phone);
    return [[array copy] retain];
}
+ (NSArray<NSDictionary *> *)getURLsCopy:(ABRecordRef)person
{
    //获取URL多值
     NSMutableArray * array = [NSMutableArray array];
    ABMultiValueRef url = ABRecordCopyValue(person, kABPersonURLProperty);
    for (int m = 0; m < ABMultiValueGetCount(url); m++)
    {
        //获取电话Label
        NSString * urlLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(url, m));
        //获取該Label下的电话值
        NSString * urlContent = (NSString*)ABMultiValueCopyValueAtIndex(url,m);
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        if(urlLabel) dic[@"label"] = urlLabel;
        if(urlContent) dic[@"content"] = urlContent;
        CFRelease(urlLabel);
        CFRelease(urlContent);
        [array addObject:dic];
    }
    
    CFRelease(url);
    return [[array copy] retain];
}
@end
