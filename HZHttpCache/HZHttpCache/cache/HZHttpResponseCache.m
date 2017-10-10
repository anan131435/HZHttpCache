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

@interface HZHttpResponseCache ()
@property (nonatomic, strong) NSMutableSet  *protectCaches;
@end

@implementation HZHttpResponseCache
{
    dispatch_queue_t _HZIOQueue;
    NSString *_cachePath;
    NSFileManager *_fileManager;
    HZCache *_memoryCache;
}
+ (instancetype)sharedCache{
    static dispatch_once_t onceToken;
    static HZHttpResponseCache *responseCache = nil;
    dispatch_once(&onceToken, ^{
        responseCache = [[HZHttpResponseCache alloc] init];
    });
    return responseCache;
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
        //清楚磁盘缓存操作放到后台操作
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDiskOnBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)cleanDiskOnBackGround{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    [self cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

}
- (void)cleanDiskWithCompletionBlock:(void(^)(void))completionBlock{
    dispatch_async(_HZIOQueue, ^{
        //获取文件夹下的枚举
        NSArray *resourceKeys = @[NSURLIsDirectoryKey,NSURLContentModificationDateKey,NSURLNameKey,NSURLLocalizedNameKey,NSURLFileAllocatedSizeKey];
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:[NSURL fileURLWithPath:_cachePath isDirectory:YES] includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
        NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:- self.maxCacheAge];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        NSMutableArray *urlsToDelete = [NSMutableArray new];
        //遍历文件夹下的文件有两个目的
        // 1.删除过期文件 2.删除比较旧的文件，使得当前文件大小，小于最大文件大小
        for (NSURL *fileUrl in fileEnumerator) {
            NSDictionary *attributesDict = [fileUrl resourceValuesForKeys:resourceKeys error:nil];
            //跳过文件夹
            if ([attributesDict[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            //跳过不能删除的文件数据，比如首页或者比较重要的数据
            if ([self.protectCaches containsObject:fileUrl.lastPathComponent]) {
                continue;
            }
            //删除过期文件
            NSDate *modicationDate = attributesDict[NSURLContentModificationDateKey];
            if ([[modicationDate laterDate:expireDate] isEqualToDate:expireDate]) {
                [urlsToDelete addObject:fileUrl];
            }
            NSNumber *totalAllocatedSize = attributesDict[NSURLFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize integerValue];
            [cacheFiles setObject:attributesDict forKey:fileUrl];
        }
        for (NSURL *url in urlsToDelete) {
            [_fileManager removeItemAtURL:url error:nil];
        }
        if (self.maxCacheAge > 0 && currentCacheSize > self.maxCacheAge) {
            NSArray *sortedArray = [cacheFiles keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
            }];
            for (NSURL *fileUrl in sortedArray) {
                if ([_fileManager removeItemAtURL:fileUrl error:nil]) {
                    NSDictionary *attributesDict = cacheFiles[fileUrl];
                    NSNumber *totalSize = attributesDict[NSURLFileAllocatedSizeKey];
                    currentCacheSize -= [totalSize integerValue];
                    if (currentCacheSize < self.maxCacheSize / 2) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
        
    });
}
- (void)clearCacheOnDisk{
    [self clearCacheOnDisk:nil];
}
- (void)clearCacheOnDisk:(void (^)(void)) complete{
    dispatch_async(_HZIOQueue, ^{
        [_fileManager removeItemAtPath:_cachePath error:nil];
        [_fileManager createDirectoryAtPath:_cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete();
            });
        }
    });
}
//删除到指定日期的缓存
- (void)deleteCacheToDate:(NSDate *)date{
    __autoreleasing NSError *error = nil;
    NSArray *cacheFiles = [_fileManager contentsOfDirectoryAtURL:[NSURL URLWithString:_cachePath] includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (error) {
        NSLog(@"fail to get cacheFile list %@",error);
    }
    dispatch_async(_HZIOQueue, ^{
        __autoreleasing NSError *checkError = nil;
        for (NSURL * fielUrl in cacheFiles) {
            NSDictionary *dictionary = [fielUrl resourceValuesForKeys:@[NSURLContentModificationDateKey] error:&checkError];
            NSDate *modicationDate = [dictionary objectForKey:NSURLContentModificationDateKey];
            if (modicationDate.timeIntervalSince1970 - date.timeIntervalSince1970 < 0) {
                [_fileManager removeItemAtURL:fielUrl error:nil];
            }
        }
    });
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
//删除特定文件
- (void)removeObjectForKey:(NSString *)key{
    [_memoryCache removeObjectForKey:key];
    NSString *filePath = [_cachePath stringByAppendingPathComponent:key];
    if ([_fileManager fileExistsAtPath:filePath]) {
        __autoreleasing NSError *error = nil;
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"remove object faild %@",error);
        }
    }
}
- (NSTimeInterval)cacheFileDuration:(NSString *)path{
    NSDictionary *attributesDict = [_fileManager attributesOfItemAtPath:path error:nil];
    if (!attributesDict) {
        NSLog(@"获取文件属性失败 %@: %@", path, attributesDict);
        return -1;
    }
    return [[attributesDict fileModificationDate] timeIntervalSinceNow];
    
}
//判断文件是否过期
- (BOOL)expiredWithCacheKey:(NSString *)cacheFileNameKey cacheDuration:(NSTimeInterval)expireduration{
    NSString *filePath = [_cachePath stringByAppendingPathComponent:cacheFileNameKey];
    if ([_fileManager fileExistsAtPath:filePath]) {
        NSTimeInterval fileDuration = [self cacheFileDuration:filePath];
        return fileDuration > expireduration;
    }else{//文件不存在则为过期
        return YES;
    }
}
- (NSMutableSet *)protectCaches{
    if (!_protectCaches) {
        _protectCaches = [[NSMutableSet alloc] init];
    }
    return _protectCaches;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
































@end
