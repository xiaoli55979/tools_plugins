#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_httpdns.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_httpdns'
  s.version          = '0.1.4'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AFNetworking'
  s.dependency 'YYCache'
  s.dependency 'Reachability'
  s.dependency 'MSDKDns_C11'
  s.static_framework = true
  s.platform = :ios, '12.0'
#  s.vendored_frameworks = 'Classes/frameworks/MSDKDns_C11.framework'
  s.libraries = 'z','sqlite3','c++','xml2','z.1.1.3','stdc++'
  s.frameworks = 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'CoreGraphics', 'Security', 'QuartzCore','CoreText','CFNetwork','MobileCoreServices'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'OTHER_LDFLAGS' => '-ObjC',
      'SWIFT_OPTIMIZATION_LEVEL' => '-Owholemodule',
      'ENABLE_BITCODE' => 'NO' # 如果你使用的 framework 不支持 bitcode，可以禁用它
    }
  s.swift_version = '5.0'
end
