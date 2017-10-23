//
//  HZRequestManager.m
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/10.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZRequestManager.h"
#import <AFHTTPRequestOperationManager.h>

@interface HZRequestManager()
@property (nonatomic, strong) AFHTTPRequestOperationManager  *requestManager;
@property (nonatomic,strong) NSMapTable *operationMethodParameters; //保存opeation参数
@end

@implementation HZRequestManager
- (instancetype)init{
    self = [super init];
    if (self) {
        self.cache = [HZHttpResponseCache sharedCache];
        self.operationMethodParameters = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
    }
    return self;
}
+ (instancetype)shareRequestManager{
    static HZRequestManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
//- (AFHTTPRequestOperationManager *)requestManager{
//    if (!_requestManager) {
//        _requestManager = [AFHTTPRequestOperationManager manager];
//        _requestManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
//        _requestManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];
//    }
//    return _requestManager;
//}














@end
