#
# Be sure to run `pod lib lint ${POD_NAME}.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZQAssistRefresh'
  s.version          = '0.1.0'
  s.summary          = '一款辅助上拉刷新，下拉加载的工具'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
一款辅助上拉刷新，下拉加载的工具
 [self.tableView addRefreshBlock:^(RefreshPageModel *page, ScrollViewRefreshSuccessBlock refreshSuccessBlock) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([page isFirstPage])
        {
            [strongSelf.dataSource removeAllObjects];
        }
        [strongSelf.dataSource addObject:@(page.pageIndex)];
        refreshSuccessBlock(RefreshStateSuccess);
    } withPage:[RefreshPageModel pageWithSize:10 index:0]];
                       DESC

  s.homepage         = 'git@github.com:KeyFive/ZQAssistRefresh.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '${USER_NAME}' => '${USER_EMAIL}' }
  s.source           = { :git => 'git@github.com:KeyFive/ZQAssistRefresh.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = '${POD_NAME}/Classes/**/*'
  
  # s.resource_bundles = {
  #   '${POD_NAME}' => ['${POD_NAME}/Assets/*.png']
  # }

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'Masonry'
  s.dependency 'MJRefresh'
end
