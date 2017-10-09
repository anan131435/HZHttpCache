//
//  NSString+HZHttpCache.h
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HZHttpCache)
- (NSString *)md5Encrypt;
+ (NSString *)appVersionString;
+ (NSString *)cacheFileKeyNameWithUrlString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params;
@end
