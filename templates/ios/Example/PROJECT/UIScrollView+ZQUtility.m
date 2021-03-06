
    //
//  UIScrollView+Utility.m
//  FlyBelt
//
//  Created by zhiqiangcao on 2017/8/3.
//  Copyright © 2017年 FB. All rights reserved.
//

#import "UIScrollView+ZQUtility.h"
#import <Masonry/Masonry.h>

@interface RefreshPageModel()

@property (nonatomic, assign) NSUInteger beginIndex;
@property (nonatomic, assign, readwrite) NSUInteger pageSize;
@property (nonatomic, assign, readwrite) NSUInteger pageIndex;
@property (nonatomic, assign) NSUInteger lastPageIndex;

@end

@implementation RefreshPageModel

+ (instancetype)pageWithSize:(NSUInteger)pageSize index:(NSUInteger)index
{
    RefreshPageModel *page = [[RefreshPageModel alloc] init];
    page.pageSize = pageSize;
    page.pageIndex = index;
    page.beginIndex = index;
    return page;
}

- (void)resetToFirstPage
{
    self.lastPageIndex = self.pageIndex;
    self.pageIndex = self.beginIndex;
}

- (void)resetToLastPage
{
    self.pageIndex = self.lastPageIndex;
}

- (void)nextPage
{
    self.lastPageIndex = self.pageIndex;
    self.pageIndex++;
}

- (BOOL)isFirstPage
{
    return self.pageIndex == self.beginIndex;
}

@end


static const void *scrollRefreshKey = &scrollRefreshKey;
static const void *scrollRefreshStateKey = &scrollRefreshStateKey;
static const void *noDataViewKey = &noDataViewKey;

@implementation UIScrollView (Utility)

- (void)addRefreshBlock:(ScrollViewRefreshBlock)refreshBlock withPage:(RefreshPageModel *)refreshPage
{
    RefreshPageModel *page = objc_getAssociatedObject(self, scrollRefreshKey);
    ScrollViewRefreshSuccessBlock stateBlock = self.refreshStateBlock;
    if (!page)
    {
        page = refreshPage;
        objc_setAssociatedObject(self, scrollRefreshKey, page, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    __weak __typeof(self) weakSelf = self;
    self.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [page resetToFirstPage];
        refreshBlock(page, stateBlock);
        [strongSelf.mj_header endRefreshing];
    }];

    self.mj_footer = [MJRefreshBackStateFooter footerWithRefreshingBlock:^{
       __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf isKindOfClass:[UITableView class]])
        {
            UITableView *tableView = (UITableView *)self;
            BOOL firstPage = YES;
            for (NSUInteger i = 0; i < [tableView numberOfSections]; i++)
            {
                if ([tableView numberOfRowsInSection:i] > 0)
                {
                    firstPage = NO;
                    break;
                }
            }

            if (firstPage)
            {
                [page resetToFirstPage];
            }
            else
            {
                [page nextPage];
            }
        }
        else
        {
            [page nextPage];
        }
        refreshBlock(page, stateBlock);
        [strongSelf.mj_footer endRefreshing];
    }];
}

- (void)addHeadRefreshBlock:(void(^)())block
{
    __weak __typeof(self) weakSelf = self;
    self.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        block();
        [strongSelf.mj_header endRefreshing];
    }];
}

#pragma mark - property

- (ScrollViewRefreshSuccessBlock)refreshStateBlock
{
    ScrollViewRefreshSuccessBlock refreshStateBlock = objc_getAssociatedObject(self, scrollRefreshStateKey);
    RefreshPageModel *page = objc_getAssociatedObject(self, scrollRefreshKey);
    if (!refreshStateBlock)
    {
        refreshStateBlock = ^(RefreshState state){
            BOOL hasData = NO;
            if ([self isKindOfClass:[UITableView class]])
            {
                UITableView *tableView = (UITableView *)self;
                [tableView reloadData];
                NSUInteger sectionCount = tableView.numberOfSections;
                for (NSUInteger i = 0; i < sectionCount; i++)
                {
                    if ([tableView numberOfRowsInSection:i] > 0)
                    {
                        hasData = YES;
                    }
                }
            }
            else if ([self isKindOfClass:[UICollectionView class]])
            {
                UICollectionView *collectionView = (UICollectionView *)self;
                [collectionView reloadData];
                NSUInteger sectionCount = collectionView.numberOfSections;
                for (NSUInteger i = 0; i < sectionCount; i++)
                {
                    if ([collectionView numberOfItemsInSection:i] > 0)
                    {
                        hasData = YES;
                    }
                }
            }
            switch (state) {
                case RefreshStateNoData:
                {
                    if (hasData)
                    {
                        [self.mj_footer endRefreshingWithNoMoreData];
                    }
                    else
                    {
                            //空页面处理
                        if (!self.noDataView.superview)
                        {
                            [self addSubview:self.noDataView];
                        }

                        NSLog(@"%@",self.noDataView.superview);
                        [self.noDataView mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.centerX.equalTo(self.mas_centerX);
                            make.centerY.equalTo(self.mas_centerY);
                        }];
                    }
                    [page resetToLastPage];
                    break;
                }
                case RefreshStateNetError:
                {
                        //网络异常处理
                    if (!hasData)
                    {
                            //空页面处理
                        if (!self.noDataView.superview)
                        {
                            [self addSubview:self.noDataView];
                        }
                        [self.noDataView mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.centerX.equalTo(self.mas_centerX);
                            make.centerY.equalTo(self.mas_centerY);
                        }];
                    }
                    [page resetToLastPage];
                    break;
                }
                case RefreshStateSuccess:
                {
                    if (hasData)
                    {
                        if (self.noDataView.superview)
                        {
                            [self.noDataView removeFromSuperview];
                        }
                    }
                    break;//成功
                }
                default:
                    break;
            }
        };
        objc_setAssociatedObject(self, scrollRefreshStateKey, refreshStateBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return refreshStateBlock;
}

- (void)setRefreshStateBlock:(ScrollViewRefreshSuccessBlock)refreshStateBlock
{
    objc_setAssociatedObject(self, scrollRefreshStateKey, refreshStateBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIView *)noDataView
{
    UIView *noDataView = objc_getAssociatedObject(self, noDataViewKey);
    if (!noDataView)
    {
        UILabel *noDataLabel = [[UILabel alloc] init];
        noDataLabel.textColor = [UIColor lightGrayColor];
        noDataLabel.text = @"暂无数据";
        noDataView = noDataLabel;
        objc_setAssociatedObject(self, noDataViewKey, noDataView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return noDataView;
}

- (void)setNoDataView:(UIView *)noDataView
{
    objc_setAssociatedObject(self, noDataViewKey, noDataView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
