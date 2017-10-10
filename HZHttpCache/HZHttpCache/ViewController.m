//
//  ViewController.m
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *array = @[@"1",@"5",@"3",@"10",@"4",@"2"];
    NSArray *sortedArray = [array sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger num1 = [obj1 integerValue];
        NSInteger num2 = [obj2 integerValue];
        if (num1 < num2) {
            return NSOrderedDescending;
        }else if (num1 == num2){
            return NSOrderedSame;
        }else{
            return NSOrderedAscending;
        }
        
    }];
    NSLog(@"%@",sortedArray);
    NSArray *stableSortedArray = [array sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger num1 = [obj1 integerValue];
        NSInteger num2 = [obj2 integerValue];
        if (num1 < num2) {
            return NSOrderedAscending;
        }else if (num1 == num2){
            return NSOrderedSame;
        }else{
            return NSOrderedDescending;
        }
        
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
