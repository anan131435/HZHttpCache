//
//  HZHttpResponseCache.m
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/9.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZHttpResponseCache.h"
#import <UIKit/UIKit.h>
static NSString *HZCacheDirectory = @"HZCacheDirectory";
static const NSInteger kDefauleCacheMazAge = 60 * 60 * 24 * 7;

@interface HZCache : NSCache

@end
@implementation HZCache
- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}
- (void)removeAllObjects{
    [super removeAllObjects];
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end



@implementation HZHttpResponseCache
{
    dispatch_queue_t _HZIOQueue;
    NSString *_cachePath;
    NSFileManager *_fileManager;
    HZCache *_memoryCache;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        _maxCacheAge = kDefauleCacheMazAge;
        _memoryCache = [[HZCache alloc] init];
        _HZIOQueue = dispatch_queue_create("cahceQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_HZIOQueue, ^{
            _fileManager = [NSFileManager defaultManager];
            //判断是否有文件夹HZCacheDirectory ，存在 干掉，创建HZCacheDirectory 文件夹
            [self checkDirectory];
        });
    }
    return self;
}
- (void)checkDirectory{
    BOOL isDirectory = nil;
    _cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:HZCacheDirectory];
    if ([_fileManager fileExistsAtPath:_cachePath isDirectory:&isDirectory]) {//存在
        if (!isDirectory) {//不是文件夹
            NSError *error = nil;
           BOOL result =  [_fileManager removeItemAtPath:_cachePath error:&error];
            if (!result) {
                NSLog(@"fail to remove directory %@",error);
            }
            [self createBaseDirectory];
        }
    }else{//不存在
        [self createBaseDirectory];
    }
}
- (void)createBaseDirectory{
    __autoreleasing NSError *error = nil;
  BOOL created = [_fileManager createDirectoryAtPath:_cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!created) {
        NSLog(@"fail to create directory %@ ",error);
    }else{
        NSURL *backupUrl = [NSURL fileURLWithPath:_cachePath];
        NSError *error = nil;
        [backupUrl setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (error) {
            NSLog(@"设置属性失败%@",error);
        }
        
    }
    
}
//读写文件
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    if (!object) {
        return;
    }
    [_memoryCache setObject:object forKey:key];
    dispatch_async(_HZIOQueue, ^{//防止阻塞UI线程所以异步提交操作，防止脏数据所以串行队列来写入
        NSString *filePath = [_cachePath stringByAppendingPathComponent:key];
        BOOL written = [NSKeyedArchiver archiveRootObject:object toFile:filePath];
        if (!written) {
            NSLog(@"写入磁盘缓存失败");
        }
    });
}
- (id<NSCoding>)objectForKey:(NSString *)key{
    id object = [_memoryCache objectForKey:key];
    if (!object) {
        NSString *filePath = [_cachePath stringByAppendingPathComponent:key];
        if ([_fileManager fileExistsAtPath:filePath]) {
            object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}
+ (instancetype)sharedCache{
    static dispatch_once_t onceToken;
    static HZHttpResponseCache *responseCache = nil;
    dispatch_once(&onceToken, ^{
        responseCache = [[HZHttpResponseCache alloc] init];
    });
    return responseCache;
}




































@end
