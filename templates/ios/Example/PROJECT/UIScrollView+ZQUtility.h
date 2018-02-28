//
//  UIScrollView+Utility.h
//  FlyBelt
//
//  Created by zhiqiangcao on 2017/8/3.
//  Copyright © 2017年 FB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MJRefresh/MJRefresh.h>

@interface RefreshPageModel : NSObject

@property (nonatomic, assign, readonly) NSUInteger pageSize;//默认10
@property (nonatomic, assign, readonly) NSUInteger pageIndex;//默认1开始

+ (instancetype)pageWithSize:(NSUInteger)pageSize index:(NSUInteger)index;
- (void)resetToFirstPage;
- (void)nextPage;
- (BOOL)isFirstPage;

@end

typedef NS_ENUM(NSUInteger,RefreshState)
{
    RefreshStateSuccess,
    RefreshStateNoData,
    RefreshStateNetError
};

typedef void(^ScrollViewRefreshSuccessBlock) (RefreshState refresgState);
typedef void(^ScrollViewRefreshBlock) (RefreshPageModel *page, ScrollViewRefreshSuccessBlock refreshSuccessBlock);

@interface UIScrollView (ZQUtility)

@property (nonatomic, strong) UIView *noDataView;//需要具有instrinsic size
@property (nonatomic, strong) UIView *netErrorView;//需要具有instrinsic size
@property (nonatomic, copy) ScrollViewRefreshSuccessBlock refreshStateBlock;

- (void)addRefreshBlock:(ScrollViewRefreshBlock)refreshBlock withPage:(RefreshPageModel *)refreshPage;//refreshSuccessBlock:传递refresh状态的标识，控制page，以及异常页面展示
- (void)addHeadRefreshBlock:(void(^)())block;
- (void)addFooterRefreshBlock:(void(^)())block;
- (void)beginRefresh;

@end
