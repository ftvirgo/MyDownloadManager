//
//  MainViewController.m
//  MyDownloadManager
//
//  Created by 蔡成汉 on 15/5/19.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "MainViewController.h"
#import "MyDownloadManager.h"
#import "MyTableViewCell.h"

#define QQURL @"http://dlsw.baidu.com/sw-search-sp/soft/2a/25677/QQ_V4.0.2.1427684136.dmg"

#define QQBroserURL @"http://dlsw.baidu.com/sw-search-sp/soft/aa/25701/qqbrowser3.4.1427703929.dmg"

#define QQMusicURL @"http://m2.pc6.com/xxj/qqmusicm.dmg"

#define NavicatPremiumURL @"http://m2.pc6.com/xxj/navicatpremiumen.dmg"


#define ImageURL1 @"http://www.sucaifengbao.com/uploadfile/photo/meinvtupianbizhi/meinvtupianbizhi_813_036.jpg"

#define ImageURL2 @"http://www.33.la/uploads/20140525bztp/15443.jpg"


@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *dataArray;
    UITableView *myTableView;
    UIBarButtonItem *barButtonItemLeft;
    
    BOOL isCancle;
}
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    barButtonItemLeft = [[UIBarButtonItem alloc]initWithTitle:@"暂停" style:UIBarButtonItemStylePlain target:self action:@selector(leftIsTouch:)];
    self.navigationItem.leftBarButtonItem = barButtonItemLeft;
    
    UIBarButtonItem *clearBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"清理" style:UIBarButtonItemStylePlain target:self action:@selector(clearBarButtonItemIsTouch:)];
    
    UIBarButtonItem *loadBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"下载" style:UIBarButtonItemStylePlain target:self action:@selector(loadBarButtonItemIsTouch:)];
    
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:loadBarButtonItem,clearBarButtonItem, nil];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    dataArray = [NSMutableArray array];
    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    myTableView.dataSource = self;
    myTableView.delegate = self;
    [self.view addSubview:myTableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"";
    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[MyTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [cell setMyTableViewCellWithURL:[dataArray objectAtIndex:indexPath.row]];
//    [cell setMyTableViewCellWihtName:[dataArray objectAtIndex:indexPath.row]];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(void)leftIsTouch:(UIBarButtonItem *)paramSender
{
    if (isCancle == NO)
    {
        isCancle = YES;
        [barButtonItemLeft setTitle:@"继续"];
        [[MyDownloadManager downloadManager]cancle];
    }
    else
    {
        isCancle = NO;
        [barButtonItemLeft setTitle:@"暂停"];
        [myTableView reloadData];
    }
}

-(void)clearBarButtonItemIsTouch:(UIBarButtonItem *)paramSender
{
    MyDownloadManager *downloadManager = [MyDownloadManager downloadManager];
    [downloadManager clear:^(BOOL success, NSUInteger size, NSError *error) {
        if (success == YES)
        {
            NSLog(@"清理成功:%ld",(unsigned long)size);
            [dataArray removeAllObjects];
            [myTableView reloadData];
            NSString *sizeString = [NSString stringWithFormat:@"共清理%.2fM空间",size/1024.0f/1024.0f];
            UIAlertView *myAlertView = [[UIAlertView alloc]initWithTitle:@"提示" message:sizeString delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [myAlertView show];
        }
        else
        {
            NSLog(@"清理失败:%@",error);
        }
    }];
    
}

-(void)loadBarButtonItemIsTouch:(UIBarButtonItem *)paramSender
{
    [dataArray removeAllObjects];
    [dataArray addObject:QQURL];
    [dataArray addObject:QQBroserURL];
    [dataArray addObject:QQMusicURL];
    
    [dataArray addObject:NavicatPremiumURL];
    
//    [dataArray addObject:ImageURL1];
//    [dataArray addObject:ImageURL2];
//    [dataArray addObject:ImageURL3];
    
//    [dataArray addObject:@"101.jpg"];
//    [dataArray addObject:@"102.jpg"];
    
    [myTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
