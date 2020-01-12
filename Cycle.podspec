Pod::Spec.new do |s|
  s.name             = 'Cycle'
  s.version          = '1.0.0'
  s.summary          = 'An experiment in unidirectional-data-flow inspired by Cycle.js.'
  s.description      = 'Cycle provides a means of expressing an app as a filter over a stream of external events.'
  s.homepage         = 'https://github.com/BrianSemiglia/Cycle.swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'brian.semiglia@gmail.com' => 'brian.semiglia@gmail.com' }
  s.source           = {
    :git => 'https://github.com/BrianSemiglia/Cycle.swift.git',
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/brians_'
  s.platforms = {
    :ios => "9.0",
    :osx => "10.10",
    :tvos => "9.0",
    :watchos => "2.0"
  }
  s.requires_arc = true
  s.swift_version = "5.0"
  s.source_files = 'Cycle/Classes/**/*'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxCocoa', '~> 5.0'
end
