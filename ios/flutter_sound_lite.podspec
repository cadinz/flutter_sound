#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
s.name = 'flutter_sound_lite'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin that relates to sound like audio and recorder.'
  s.description      = <<-DESC
Flutter plugin that relates to sound like audio and recorder.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AudioKit', '~> 4.0'
  s.ios.deployment_target = '9.3'
  s.static_framework = true

end
