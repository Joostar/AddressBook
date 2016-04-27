//
//  ViewController.m
//  AddressBookExample
//
//  Created by maying on 16/4/27.
//  Copyright © 2016年 maying. All rights reserved.
//

#import "ViewController.h"

#import "JooAddressBook.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    int keys[10] =
    {
        kABPersonFirstNameProperty,
        kABPersonLastNameProperty,
        kABPersonMiddleNameProperty,
        kABPersonNicknameProperty,
        kABPersonOrganizationProperty,
        kABPersonEmailProperty,
        kABPersonAddressProperty,
        kABPersonPhoneProperty,
        kABPersonRelatedNamesProperty,
        kABPersonHeadImageProperty
    };
    
    NSMutableArray * keysArray  = [NSMutableArray array];
    for(int i = 0;i < 10;i++)
        [keysArray addObject:[NSNumber numberWithInt:keys[i]]];
    
    NSArray * contacts = [JooAddressBook getAllContacts:keys keysCount:10 progressBlock:^(const int total, const int current)
    {
        NSLog(@"%d,%d",total,current);
        
    } refusedAccessBlock:^{
        NSLog(@"");
    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
