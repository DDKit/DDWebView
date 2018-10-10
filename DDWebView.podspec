#
# Be sure to run `pod lib lint DDWebView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DDWebView'
  s.version          = '0.1.1'
  s.summary          = '简单描述一下 DDWebView 的用途:就是用来测试搭建开源三方库的!'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
简单描述一下 DDSwiftKit 的用途:就是用来测试搭建开源三方库的!
简单描述一下 DDSwiftKit 的用途:就是用来测试搭建开源三方库的!
简单描述一下 DDSwiftKit 的用途:就是用来测试搭建开源三方库的!
简单描述一下 DDSwiftKit 的用途:就是用来测试搭建开源三方库的!
DESC

  s.homepage         = 'https://github.com/DDKit/DDWebView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'duanchanghe' => '592110272@qq.com' }
  s.source           = { :git => 'https://github.com/DDKit/DDWebView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'DDWebView/Classes/**/*'
  s.swift_version = '4.0'

  # s.resource_bundles = {
  #   'DDWebView' => ['DDWebView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'MBProgressHUD'

end
