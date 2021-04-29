Pod::Spec.new do |s|
  s.name             = 'StateMachine'
  s.version          = '1.0.0'
  s.summary          = 'StateMachine'
  s.description      = <<-DESC
StateMachine
                       DESC

  s.homepage         = 'https://github.com/sergejs/StateMachine'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sergejs Smirnovs' => 'sergey@nbi.me' }
  s.source           = { :git => 'https://github.com/sergejs/StateMachine.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'Sources/StateMachine/**/*'
  s.dependency 'SwiftLogger'
end
