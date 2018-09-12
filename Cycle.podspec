Pod::Spec.new do |s|
  s.name             = 'Cycle'
  s.version          = '0.0.14'
  s.summary          = 'An experiment in unidirectional-data-flow inspired by Cycle.js.'
  s.description      = 'Cycle provides a means of writing an app as a filter over a stream of external events.'
  s.homepage         = 'https://github.com/BrianSemiglia/Cycle.swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'brian.semiglia@gmail.com' => 'brian.semiglia@gmail.com' }
  s.source           = { :git => 'https://github.com/BrianSemiglia/Cycle.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/brians_'
  s.ios.deployment_target = '9.0'
  s.source_files = 'Cycle/Classes/**/*'
  s.dependency 'RxSwift',   '~> 4.0'
  s.dependency 'Changeset', '3.1'
end
