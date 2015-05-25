//
//  MyDownloadManager.h
//  MyDownloadManager
//
//  Created by 蔡成汉 on 15/5/19.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyDownloadManager : NSObject

/**
 *  初始化方法
 *
 *  @return MyDownloadManager
 */
+(MyDownloadManager *)downloadManager;

/**
 *  开始下载
 *
 *  @param urlString 目标URL - URLString
 *  @param result    下载结果
 *  @param complete  下载完成
 */
-(void)downloadWithURL:(NSString *)urlString
                     result:(void(^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesNeedRead))result
                   completion:(void(^)(BOOL complete, NSString *pathString , NSString *name, NSError *error))completion;

/**
 *  开始下载
 *
 *  @param urlString 目标URL -- URLString
 *  @param clear     是否清除缓存 -- 默认为NO，不清理缓存。如果设置为YES，则会清理已经下载的文件再重新下载
 *  @param result    下载结果
 *  @param complete  下载完成
 */
-(void)downloadWithURL:(NSString *)urlString
           clearDataIfExist:(BOOL)clear
                     result:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesNeedRead))result
                   completion:(void (^)(BOOL complete, NSString *pathString, NSString *name, NSError *error))completion;

/**
 *  取消下载
 */
-(void)cancle;

/**
 *  取消下载 -- 取消某一个下载
 *
 *  @param string 目标url
 */
-(void)cancleDownloadWithURL:(NSString *)string;


/**
 *  清理已下载文件 -- 所有文件
 *
 *  @param result 清理的结果
 */
-(void)clear:(void(^)(BOOL success , NSUInteger size , NSError *error))result;

/**
 *  清理已下载文件 -- 指定文件
 *
 *  @param name   文件的URL
 *  @param result 清理结果
 */
-(void)clearWihtName:(NSString *)name result:(void(^)(BOOL success , NSUInteger size , NSError *error))result;

/**
 *  获取文件路径 -- 根据文件名
 *
 *  @param string 文件URL
 *  @param path   block返回的文件路径
 */
-(void)getFilePathWithURL:(NSString *)string path:(void(^)(NSString *path))path;

@end
