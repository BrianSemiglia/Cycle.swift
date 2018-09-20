Pod::Spec.new do |s|
  s.name             = 'Cycle'
  s.version          = '0.0.18'
  s.summary          = 'An experiment in unidirectional-data-flow inspired by Cycle.js.'
  s.description      = 'Cycle provides a means of writing an app as a filter over a stream of external events.'
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
  s.swift_version = "4.2"
  s.default_subspec = "Core"
  s.subspec "Core" do |ss|
    ss.source_files  = "Sources/**/*.{h,m,swift}"
    ss.framework  = "Foundation"
  end
  s.dependency 'RxSwift',   '~> 4.3.0'
  s.dependency 'Changeset', '3.1'
end
