#
# Be sure to run `pod lib lint Cycle.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Cycle'
  s.version          = '0.0.1'
  s.summary          = 'An experiment in unidirectional-data-flow inspired by Cycle.js.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Cycle provides a means of writing an app as a filter over a stream of external events.'

  s.homepage         = 'https://github.com/BrianSemiglia/Cycle.swift'
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'brian.semiglia@gmail.com' => 'brian.semiglia@gmail.com' }
  s.source           = { :git => 'https://github.com/BrianSemiglia/Cycle.swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/brians_'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Cycle/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Cycle' => ['Cycle/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'RxSwift', '3.2.0'
  s.dependency 'Changeset', '2.1'
end
