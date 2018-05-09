
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
static const void *netErrorViewKey = &netErrorViewKey;

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
        [strongSelf.mj_footer resetNoMoreData];
        refreshBlock(page, stateBlock);
    }];

    self.mj_footer = [MJRefreshBackStateFooter footerWithRefreshingBlock:^{
        refreshBlock(page, stateBlock);
    }];
}

- (void)addHeadRefreshBlock:(void(^)(void(^)(void)))block;
{
    __weak __typeof(self) weakSelf = self;
    self.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        __weak __typeof(strongSelf) weakSelf = strongSelf;
        block(^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.mj_header endRefreshing];
        });
    }];
}

- (void)addFooterRefreshBlock:(void(^)(void(^)(void)))block
{
    __weak __typeof(self) weakSelf = self;
    self.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        __weak __typeof(strongSelf) weakSelf = strongSelf;
        block(^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.mj_footer endRefreshing];
        });
    }];
}

- (void)showNoDataView
{
    if (!self.noDataView.superview)
    {
        [self addSubview:self.noDataView];
        __weak __typeof(self) weakSelf = self;
        [self.noDataView mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            make.center.equalTo(strongSelf);
        }];
    }
}

- (void)showNetErrorView
{
    if (!self.netErrorView.superview)
    {
        [self addSubview:self.netErrorView];
        __weak __typeof(self) weakSelf = self;
        [self.netErrorView mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            make.center.equalTo(strongSelf);
        }];
    }
}

- (void)hideNoDataView
{
    if (self.noDataView.superview)
    {
        [self.noDataView removeFromSuperview];
    }
}

- (void)hideNetErrorView
{
    if (self.netErrorView.superview)
    {
        [self.netErrorView removeFromSuperview];
    }
}

- (void)beginRefresh
{
    [self.mj_header beginRefreshing];
}

#pragma mark - property

- (ScrollViewRefreshSuccessBlock)refreshStateBlock
{
    ScrollViewRefreshSuccessBlock refreshStateBlock = objc_getAssociatedObject(self, scrollRefreshStateKey);
    if (!refreshStateBlock)
    {
        __weak __typeof(self) weakSelf = self;
        refreshStateBlock = ^(RefreshState state){
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            __weak __typeof(strongSelf) weakSelf = strongSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf hideNetErrorView];
                [strongSelf hideNoDataView];
                RefreshPageModel *page = objc_getAssociatedObject(self, scrollRefreshKey);
                BOOL hasData = NO;
                if ([strongSelf isKindOfClass:[UITableView class]])
                {
                    UITableView *tableView = (UITableView *)self;
                    [tableView reloadData];
                    NSUInteger sectionCount = tableView.numberOfSections;
                    for (NSUInteger i = 0; i < sectionCount; i++)
                    {
                        if ([tableView numberOfRowsInSection:i] > 0)
                        {
                            hasData = YES;
                            break;
                        }
                    }
                }
                else if ([strongSelf isKindOfClass:[UICollectionView class]])
                {
                    UICollectionView *collectionView = (UICollectionView *)self;
                    [collectionView reloadData];
                    NSUInteger sectionCount = collectionView.numberOfSections;
                    for (NSUInteger i = 0; i < sectionCount; i++)
                    {
                        if ([collectionView numberOfItemsInSection:i] > 0)
                        {
                            hasData = YES;
                            break;
                        }
                    }
                }
                if ([page isFirstPage])
                {
                    [strongSelf.mj_header endRefreshing];
                }
                else{
                    if (state == RefreshStateNoData && hasData)
                    {
                        [strongSelf.mj_footer endRefreshingWithNoMoreData];
                    }
                    else
                    {
                        [strongSelf.mj_footer endRefreshing];
                    }
                }
                switch (state) {
                    case RefreshStateNoData:
                    {
                        if (!hasData)
                        {
                                //空页面处理
                            [strongSelf showNoDataView];
                        }
                        break;
                    }
                    case RefreshStateNetError:
                    {
                            //网络异常处理
                        if (!hasData)
                        {
                                //空页面处理
                            [strongSelf showNetErrorView];
                        }
                        break;
                    }
                    case RefreshStateSuccess:
                    {
                        if (hasData)
                        {
                            [page nextPage];
                        }
                        else
                        {
                            [strongSelf showNoDataView];
                        }
                        break;//成功
                    }
                    default:
                        break;
                }
            });
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

- (UIView *)netErrorView
{
    UIView *netErrorView = objc_getAssociatedObject(self, netErrorViewKey);
    if (!netErrorView)
    {
        UILabel *netErrorLabel = [[UILabel alloc] init];
        netErrorLabel.textColor = [UIColor lightGrayColor];
        netErrorLabel.text = @"网络加载出错，清稍后再试";
        netErrorView = netErrorLabel;
        objc_setAssociatedObject(self, netErrorViewKey, netErrorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return netErrorView;
}

- (void)setNoDataView:(UIView *)noDataView
{
    objc_setAssociatedObject(self, noDataViewKey, noDataView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setNetErrorView:(UIView *)netErrorView
{
    objc_setAssociatedObject(self, netErrorViewKey, netErrorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
