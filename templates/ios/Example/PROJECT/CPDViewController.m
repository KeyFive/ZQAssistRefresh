//
//  CPDViewController.m
//  PROJECT
//
//  Created by PROJECT_OWNER on TODAYS_DATE.
//  Copyright (c) TODAYS_YEAR PROJECT_OWNER. All rights reserved.
//

#import "CPDViewController.h"
#import "UIScrollView+ZQUtility.h"

@interface CPDViewController ()
<
    UITableViewDelegate,
    UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation CPDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"test"];
    __weak __typeof(self) weakSelf = self;
    [self.tableView addRefreshBlock:^(RefreshPageModel *page, ScrollViewRefreshSuccessBlock refreshSuccessBlock) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([page isFirstPage])
        {
            [strongSelf.dataSource removeAllObjects];
        }

        if (strongSelf.dataSource.count > 20)
        {
            refreshSuccessBlock(RefreshStateNoData);
        }
        else
        {
            for (NSUInteger i = 0; i < 10; i++)
            {
                [strongSelf.dataSource addObject:@(page.pageIndex)];
            }
            refreshSuccessBlock(RefreshStateSuccess);
        }
    } withPage:[RefreshPageModel pageWithSize:10 index:0]];
    [self.tableView.mj_header beginRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"test"];
    NSNumber *index =self.dataSource[indexPath.row];
    cell.textLabel.text = index.stringValue;
    return cell;
}

#pragma mark - property

- (NSMutableArray *)dataSource
{
    if (!_dataSource)
    {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
