//
//  MyTableViewCell.m
//  MyDownloadManager
//
//  Created by 蔡成汉 on 15/5/19.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "MyTableViewCell.h"
#import "MyDownloadManager.h"
#import "AdditionFrameworks.h"

@interface MyTableViewCell ()

@property (nonatomic , strong) UIImageView *myImageView;
@property (nonatomic , strong) UILabel *downloadState;

@end

@implementation MyTableViewCell
@synthesize myImageView;
@synthesize downloadState;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initiaMyTableViewCell];
    }
    return self;
}

-(void)initiaMyTableViewCell
{
    myImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    myImageView.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:myImageView];
    
    downloadState = [[UILabel alloc]initWithFrame:CGRectMake(100, 0, 100, 60)];
    downloadState.text = @"等待下载";
    [self.contentView addSubview:downloadState];
}

-(void)setMyTableViewCellWithURL:(NSString *)urlString
{
    MyDownloadManager *manager = [MyDownloadManager downloadManager];
    [manager downloadWithURL:urlString result:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesNeedRead) {
        CGFloat tpProgress;
        if (totalBytesExpectedToRead == 0)
        {
            tpProgress = 100;
        }
        else
        {
            tpProgress = (float)(totalBytesRead+(totalBytesNeedRead -totalBytesExpectedToRead))/(float)totalBytesNeedRead*100;
        }
        NSString *progress = [NSString stringWithFormat:@"%.2f",tpProgress];
        if ([progress isEqualToString:@"100.00"])
        {
            downloadState.text = @"下载完成";
        }
        else
        {
            downloadState.text = [NSString stringWithFormat:@"%@%@",progress,@"\%"];
        }
    } completion:^(BOOL complete, NSString *pathString, NSString *name, NSError *error) {
//        myImageView.image = [UIImage imageWithContentsOfFile:pathString];
        if (complete)
        {
            downloadState.text = @"下载完成";
        }
        else
        {
            downloadState.text = @"下载失败";
        }
    }];
}

-(void)setMyTableViewCellWihtName:(NSString *)string
{
    //获取文件路径
    NSString *path = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:string];

    UIImage *image = [UIImage imageWithContentsOfFile:path];
    myImageView.image = image;
}

-(void)setMyTableViewCellWihtDic:(NSDictionary *)dic
{
    if (dic != nil)
    {
        //获取数据
        
    }
}


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
