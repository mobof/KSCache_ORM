#
# Be sure to run `pod lib lint KSCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KSCache'
  s.version          = '0.0.1'
  s.summary          = 'An library for Using SQLite as ORM.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

    s.description      = <<-DESC
			 Using SQLite in an elegant way through ORM
                         DESC

  s.homepage         = 'https://github.com/spinery/KSCache_ORM'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'spinery' => '328369807@qq.com' }
  s.source           = { :git => 'https://github.com/spinery/KSCache_ORM.git', :tag => s.version }

  s.platform     = :ios, "9.0"
  s.requires_arc = true
  s.source_files = 'KSCache/**/*'
  s.public_header_files = "KSCache/KSDB.h"
  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'OTHER_CFLAGS' => '-DSQLITE_HAS_CODEC',
  }
  s.dependency 'SQLCipher'
end
