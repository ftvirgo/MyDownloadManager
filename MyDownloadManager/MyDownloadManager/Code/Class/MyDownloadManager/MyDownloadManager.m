//
//  MyDownloadManager.m
//  MyDownloadManager
//
//  Created by 蔡成汉 on 15/5/19.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "MyDownloadManager.h"
#import "AFNetworking.h"
#import "AdditionFrameworks.h"

/**
 *  默认下载文件存储位置
 */
#define MyDownloadDataSavePath @"%@/Library/Caches/MyDownloadDataSavePath"

/**
 *  默认下载文件信息存储位置
 */
#define MyDownloadDataInfoSavePath @"%@/Library/Caches/MyDownloadDataSavePath/DataInfo"

static MyDownloadManager *downloadManager;

@interface MyDownloadManager ()

@property (nonatomic , strong) NSOperationQueue *operationQueue;

@end

@implementation MyDownloadManager
@synthesize operationQueue;

/**
 *  初始化方法
 *
 *  @return MyDownloadManager
 */

+(MyDownloadManager *)downloadManager
{
    @synchronized (self)
    {
        if (downloadManager == nil)
        {
            downloadManager = [[self alloc] init];
        }
    }
    return downloadManager;
}

-(id)init
{
    self = [super init];
    if (self)
    {
        //创建存储路径
        [self creatSavePath];
        
        //创建文件信息存储路径
        [self creatDataInfoSavaPath];
        
        //创建线程池
        operationQueue = [[NSOperationQueue alloc]init];
    }
    return self;
}

/**
 *  开始下载
 *
 *  @param urlString 目标URL - URLString
 *  @param result    下载结果
 *  @param complete  下载完成
 */
-(void)downloadWithURL:(NSString *)urlString
                     result:(void(^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesNeedRead))result
                   completion:(void(^)(BOOL complete, NSString *pathString , NSString *name, NSError *error))completion
{
    [self downloadWithURL:urlString clearDataIfExist:NO result:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesNeedRead) {
        result(bytesRead,totalBytesRead,totalBytesExpectedToRead,totalBytesNeedRead);
    } completion:^(BOOL complete, NSString *pathString, NSString *name, NSError *error) {
        completion(complete,pathString,name,error);
    }];
}

/**
 *  开始下载
 *
 *  @param urlString 目标URL -- URLString
 *  @param clear     是否清除缓存 -- 默认为NO，不清理缓存。
 *  @param result    下载结果
 *  @param complete  下载完成
 */
-(void)downloadWithURL:(NSString *)urlString
           clearDataIfExist:(BOOL)clear
                     result:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead , long long totalBytesNeedRead))result
                   completion:(void (^)(BOOL, NSString *, NSString *, NSError *))completion
{
    //创建请求 -- 判断请求是否已存在 -- URL
    for (AFHTTPRequestOperation *tpOperation in operationQueue.operations)
    {
        if ([tpOperation.name isEqualToString:urlString.md5])
        {
            //表明线程已经存在，则只需要启动这个线程即可。
            [tpOperation start];
            return;
        }
    }
    
    //判断是否是清理下载
    if (clear == NO)
    {
        //非清理下载 -- 断点下载
        //判断缓存是否完成 -- 如果缓存完成，则直接返回缓存的数据；否则进行网络下载 -- 是否断点
        NSDictionary *dataInfoDic = [self readData:urlString];
        BOOL isFinish = [[dataInfoDic objectForKey:@"isFinish"]boolValue];
        if (isFinish == YES)
        {
            //数据已缓存，直接获取数据返回
            //数据已缓存 -- 则直接获取数据而不建立连接
            NSString *haveNeedLength = [dataInfoDic objectForKey:@"length"];
            long long totalBytesNeedRead = [haveNeedLength longLongValue];
            NSString *tpName = [NSString stringWithFormat:@"%@",urlString.md5];
            NSString *tpPath = [self creatDataPath:urlString];
            result(0 , 0 , 0 ,totalBytesNeedRead);
            completion(YES , tpPath , tpName , nil);
            return;
        }
    }
    
    //创建请求
    NSMutableURLRequest *request = [self creatRequestWithURL:urlString clearDataIfExist:clear];
    
    //创建连接 -- 并请求
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    requestOperation.name = urlString.md5;
    NSString *pathString = [self creatDataPath:urlString];
    
    //设置输出流的存储位置
    requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:pathString append:YES];
    
    //将请求连接放到线程池中
    NSLog(@"开始前线程个数 = %ld",(unsigned long)operationQueue.operations.count);
    [operationQueue addOperation:requestOperation];
    
    //由于block的机制导致block的回调方法里如果调用自己的方法，需要使用__weak创建一个self，指向self。
    __weak MyDownloadManager *weakSelf = self;
    
    //设置下载进度block
    [requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        long long totalBytesNeedRead;
        if (clear == NO)
        {
            //需要支持断点下载，则需要保存下载信息
            NSMutableDictionary *tpDataDic = [NSMutableDictionary dictionary];
            [tpDataDic setObject:urlString forKey:@"url"];
            [tpDataDic setValue:[NSString stringWithFormat:@"%lld",totalBytesExpectedToRead] forKey:@"length"];
            [tpDataDic setObject:[NSNumber numberWithBool:NO] forKey:@"isFinish"];
            [weakSelf writeData:tpDataDic];
            
            NSDictionary *dataInfoDic = [weakSelf readData:urlString];
            NSString *haveNeedLength = [dataInfoDic objectForKey:@"length"];
            totalBytesNeedRead = [haveNeedLength longLongValue];
        }
        else
        {
            //不需要支持断点下载
            totalBytesNeedRead = totalBytesExpectedToRead;
        }
        
        //保险起见
        if (totalBytesNeedRead == 0)
        {
            totalBytesNeedRead = totalBytesExpectedToRead;
        }
        result(bytesRead , totalBytesRead , totalBytesExpectedToRead ,totalBytesNeedRead);
    }];
    
    //设置下载结束block
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //请求完成
        NSMutableDictionary *tpDataDic = [NSMutableDictionary dictionary];
        [tpDataDic setObject:[operation.request.URL absoluteString] forKey:@"url"];
        [tpDataDic setObject:[NSNumber numberWithBool:YES] forKey:@"isFinish"];
        [weakSelf writeData:tpDataDic];
        
        NSString *urlString = [NSString stringWithFormat:@"%@",operation.request.URL];
        NSString *tpName = [NSString stringWithFormat:@"%@",urlString.md5];
        NSString *tpPath = [weakSelf creatDataPath:urlString];
        completion(YES , tpPath , tpName , nil);
        NSLog(@"下载完成线程个数 = %ld",(unsigned long)operationQueue.operations.count);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        //请求失败
        NSMutableDictionary *tpDataDic = [NSMutableDictionary dictionary];
        [tpDataDic setObject:[NSNumber numberWithBool:NO] forKey:@"isFinish"];
        [weakSelf writeData:tpDataDic];
        
        NSString *urlString = [NSString stringWithFormat:@"%@",operation.request.URL];
        NSString *tpName = [NSString stringWithFormat:@"%@",urlString.md5];
        NSString *tpPath = [weakSelf creatDataPath:urlString];
        if([error code] == NSURLErrorCancelled)
        {
            
        }
        else
        {
            completion(NO , tpPath , tpName , error);
        }
        NSLog(@"下载失败线程个数 = %ld",(unsigned long)operationQueue.operations.count);
        
    }];
    
    //开始请求 -- 异步多线程
    [requestOperation start];
    NSLog(@"开始后线程个数 = %ld",(unsigned long)operationQueue.operations.count);
}

/**
 *  取消下载
 */
-(void)cancle
{
    [operationQueue cancelAllOperations];
}

/**
 *  取消下载 -- 取消某一个下载
 *
 *  @param string 目标url
 */
-(void)cancleDownloadWithURL:(NSString *)string
{
    for (AFHTTPRequestOperation *tpOperation in operationQueue.operations)
    {
        if ([[tpOperation.request.URL absoluteString] isEqualToString:string])
        {
            [tpOperation cancel];
        }
    }
}

/**
 *  清理已下载文件 -- 所有文件
 *
 *  @param result 清理的结果
 */
-(void)clear:(void(^)(BOOL success , NSUInteger size , NSError *error))result
{
    //先取消所有的下载
    [self cancle];
    
    __weak MyDownloadManager *weakSelf = self;
    
    //获取文件存储路径
    NSString *dataPathString = [NSString stringWithFormat:MyDownloadDataSavePath, NSHomeDirectory()];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [self getSizeWithPath:dataPathString completion:^(NSUInteger size) {
        NSError *error;
        BOOL removeItemSuccess = [fileManager removeItemAtPath:dataPathString error:&error]    ;
        [weakSelf creatSavePath];
        [weakSelf creatDataInfoSavaPath];
        if (result)
        {
            result(removeItemSuccess , size,error);
        }
    }];
}

/**
 *  清理已下载文件 -- 指定文件
 *
 *  @param name   文件的URL
 *  @param result 清理结果
 */
-(void)clearWihtName:(NSString *)name result:(void(^)(BOOL success , NSUInteger size , NSError *error))result
{
    //先取消所有的下载
    [self cancle];
    
    //获取文件长度
    NSUInteger size = (unsigned long)[self getCachPahtByURL:name];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    //移除文件
    //获取文件存储路径
    NSString *dataPathString = [self creatDataPath:name];
    BOOL removeDataSuccess = [fileManager removeItemAtPath:dataPathString error:&error];
    
    //移除文件信息
    NSString *dataInfoPaht = [self creatDataInfoPath:name];
    BOOL removeDataInfoSuccess = [fileManager removeItemAtPath:dataInfoPaht error:&error];
    
    BOOL removeItemSuccess = NO;
    if (removeDataSuccess && removeDataInfoSuccess)
    {
        removeItemSuccess = YES;
    }
    [self creatSavePath];
    [self creatDataInfoSavaPath];
    if (result)
    {
        result(removeItemSuccess ,size,error);
    }
}


/**
 *  获取文件路径 -- 根据文件名
 *
 *  @param string 文件URL
 *  @param path   block返回的文件路径
 */
-(void)getFilePathWithURL:(NSString *)string path:(void(^)(NSString *path))path
{
    NSString *pathString = [self creatDataPath:string];
    if (path)
    {
        path(pathString);
    }
}

/**
 *  创建请求
 *
 *  @param string 文件下载URL
 *  @param clear  是否清理已下载文件
 *
 *  @return 返回创建的请求
 */
-(NSMutableURLRequest *)creatRequestWithURL:(NSString *)string clearDataIfExist:(BOOL)clear
{
    NSURL *url = [NSURL URLWithString:string];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5*60];
    
    if (clear == NO)
    {
        //设置请求头 -- 从哪个位置开始下载 -- 需要获取本地已缓存的文件大小
        long long length = [self getCachPahtByURL:string];
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-",length] forHTTPHeaderField:@"Range"];
    }
    return request;
}

/**
 *  获取已下载的文件的长度
 *
 *  @param string 文件url
 *
 *  @return 已下载的文件的长度
 */
-(long long)getCachPahtByURL:(NSString *)string
{
    NSString *pathString = [self creatDataPath:string];
    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:pathString];
    NSData* contentData = [fh readDataToEndOfFile];
    return contentData ? contentData.length : 0;
}

/**
 *  创建存储路径
 */
-(BOOL)creatSavePath
{
    BOOL success = NO;
    NSString *pathString = [NSString stringWithFormat:MyDownloadDataSavePath, NSHomeDirectory()];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL dataSavePathExist = [fileManager fileExistsAtPath:pathString];
    if (dataSavePathExist == NO)
    {
        //路径不存在，则创建
        BOOL creatResult = [fileManager createDirectoryAtPath:pathString withIntermediateDirectories:YES attributes:nil error:nil];
        if (creatResult == YES)
        {
            NSLog(@"创建文件下载路径成功");
            success = YES;
        }
        else
        {
            NSLog(@"创建文件下载路径失败");
            success = NO;
        }
    }
    else
    {
        NSLog(@"文件下载路径已创建");
        success = YES;
    }
    return success;
}

/**
 *  创建文件信息存储路径
 */
-(BOOL)creatDataInfoSavaPath
{
    BOOL success = NO;
    NSString *pathString = [NSString stringWithFormat:MyDownloadDataInfoSavePath, NSHomeDirectory()];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL dataInfoSavePathExist = [fileManager fileExistsAtPath:pathString];
    if (dataInfoSavePathExist == NO)
    {
        //路径不存在，则创建
        BOOL creatResult = [fileManager createDirectoryAtPath:pathString withIntermediateDirectories:YES attributes:nil error:nil];
        if (creatResult == YES)
        {
            NSLog(@"创建文件信息路径成功");
            success = YES;
        }
        else
        {
            NSLog(@"创建文件信息路径失败");
            success = NO;
        }
    }
    else
    {
        NSLog(@"文件信息路径已创建");
        success = YES;
    }
    return success;
}

/**
 *  构建文件路径 -- 根据文件下载url -- 这个路径不需要创建，只需构建即可
 *
 *  @param string 文件下载url
 *
 *  @return 文件下载路径
 */
-(NSString *)creatDataPath:(NSString *)string
{
    NSString *path = [NSString stringWithFormat:[NSString stringWithFormat:@"%@/%@",MyDownloadDataSavePath,string.md5],NSHomeDirectory()];
    return path;
}

-(NSString *)creatDataInfoPath:(NSString *)string
{
    NSString *path = [NSString stringWithFormat:[NSString stringWithFormat:@"%@/%@",MyDownloadDataInfoSavePath,string.md5],NSHomeDirectory()];
    return path;
}

/**
 *  读取文件信息 -- 根据文件url
 *
 *  @param string 文件url
 */

/**
 *  读取文件信息
 *
 *  @param string 文件信息
 *
 *  @return 文件信息字典
 */
-(NSDictionary *)readData:(NSString *)string
{
    NSString *path = [self creatDataInfoPath:string];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (dic == nil)
    {
        dic = [NSMutableDictionary dictionary];
        [dic setObject:@"" forKey:@"url"];
        [dic setObject:@"0" forKey:@"length"];
        [dic setObject:[NSNumber numberWithBool:NO] forKey:@"isFinish"];
    }
    return dic;
}

/**
 *  写入文件信息
 *
 *  @param string 文件url
 */
-(void)writeData:(NSDictionary *)dic
{
    //对写入的文件进行判断 -- 如果finish为NO，则判断长度是否为0，如果为0则存储最新的长度。如果finish为YES，则只需更改finish值为YES即可。
    NSString *urlString = [dic getStringValueForKey:@"url"];
    NSDictionary *dataInfoDic = [self readData:urlString];
    BOOL isFinish = [dic getBoolValueForKey:@"isFinish"];
    if (isFinish == NO)
    {
        NSString *length = [dataInfoDic objectForKey:@"length"];
        if ([length isEqualToString:@"0"])
        {
            //为第一次存储，则需要获取这个长度，为文件的总长度。
            NSString *newLength = [dic objectForKey:@"length"];
            [dataInfoDic setValue:newLength forKey:@"length"];
            [dataInfoDic setValue:urlString forKey:@"url"];
            [dataInfoDic setValue:[NSNumber numberWithBool:NO] forKey:@"isFinish"];
            [dataInfoDic writeToFile:[self creatDataInfoPath:urlString] atomically:YES];
        }
    }
    else
    {
        [dataInfoDic setValue:[NSNumber numberWithBool:YES] forKey:@"isFinish"];
        [dataInfoDic writeToFile:[self creatDataInfoPath:urlString] atomically:YES];
    }
}

/**
 *  获取文件路径下的文件大小
 *
 *  @param string 文件路径
 *
 *  @return 该路径下的文件大小
 */
- (void)getSizeWithPath:(NSString *)string completion:(void(^)(NSUInteger size))completion
{
    __block NSUInteger size = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:string];
        for (NSString *fileName in fileEnumerator)
        {
            NSString *filePath = [string stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(size);
            });
        }
    });
}

@end
