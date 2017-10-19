ZQAssistRefresh
============
一个辅助分页刷新的工具

## Getting started

pod 'ZQAssistRefresh'

## Best practices

[self.tableView addRefreshBlock:^(RefreshPageModel *page, ScrollViewRefreshSuccessBlock refreshSuccessBlock) {
__strong __typeof(weakSelf) strongSelf = weakSelf;
if ([page isFirstPage])
{
[strongSelf.dataSource removeAllObjects];
}
[strongSelf.dataSource addObject:@(page.pageIndex)];
refreshSuccessBlock(RefreshStateSuccess);
} withPage:[RefreshPageModel pageWithSize:10 index:0]];

## Requirements:

- CocoaPods 1.0.0+
