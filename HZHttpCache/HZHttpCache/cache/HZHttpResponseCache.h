//
//  HZHttpResponseCache.h
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZHttpResponseCache : NSObject
//最大缓存时间 单位秒
@property (nonatomic, assign) NSInteger maxCacheAge;
//最大缓存空间 单位bytes
@property (nonatomic, assign) NSInteger maxCacheSize;
//获得单例
+ (instancetype)sharedCache;
//不做内存删除的数据
- (void)addProtectCacheKey:(NSString *)key;
#pragma mark - 数据操作
//设置缓存数据
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key;
//获取缓存数据
- (id <NSCoding>)objectForKey:(NSString *)key;
#pragma mark - 删除操作
//删除指定的缓存
- (void)removeObjectForKey:(NSString *)key;
//删除到指定日期的缓存
- (void)deleteCacheToDate:(NSDate *)date;
//删除所有缓存
- (void)clearCacheOnDisk;
#pragma mark - 工具方法
//文件存在时间
- (NSTimeInterval)cacheFileDuration:(NSString *)path;
//判断一个文件是否过期
- (BOOL)expiredWithCacheKey:(NSString *)cacheFileNameKey cacheDuration:(NSTimeInterval)duration;


























@end
