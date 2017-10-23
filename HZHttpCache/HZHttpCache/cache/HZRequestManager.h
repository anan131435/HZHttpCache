//
//  HZRequestManager.h
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/10.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "HZHttpResponseCache.h"
typedef void(^requestCompleteBlock)(id result,NSError *error,BOOL isFromCache,AFHTTPRequestOperation *operation);
typedef void(^extendBlock)(id data,id formData);
@interface HZRequestManager : NSObject
@property (nonatomic, strong) HZHttpResponseCache  *cache;
+ (instancetype)shareRequestManager;
- (AFHTTPRequestOperation *)httpRequestMehtod:(NSString *)method
                                    urlString:(NSString *)urlString
                                       params:(NSDictionary *)params
                             startImmediately:(BOOL)startImmediately
                                  ignoreCaceh:(BOOL)ignoreCache
                          resultCacheDuration:(NSTimeInterval)resultCacheDuration
                                       extend:(extendBlock)extendBlock
                            completionHandler:(requestCompleteBlock)completeBlock;
@end
