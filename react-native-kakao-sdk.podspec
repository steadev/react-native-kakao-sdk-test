require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'
kakao_sdk_version = "2.11.1"

Pod::Spec.new do |s|
  s.name         = "react-native-kakao-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/steadev/react-native-kakao-sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"

  # Don't install the dependencies when we run `pod install` in the old architecture.
  if ENV['RCT_NEW_ARCH_ENABLED'] == '1' then
    s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
    s.pod_target_xcconfig    = {
        "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
        "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
    }

    s.dependency "React-Codegen"
    s.dependency "RCT-Folly"
    s.dependency "RCTRequired"
    s.dependency "RCTTypeSafety"
    s.dependency "ReactCommon/turbomodule/core"

    if defined?($KakaoSDKVersion)
      Pod::UI.puts "#{s.name}: Using user specified Kakao SDK version '#{$KakaoSDKVersion}'"
      kakao_sdk_version = $KakaoSDKVersion
    end

    # 전체 추가
    s.dependency 'KakaoSDK', kakao_sdk_version
    # 필요한 모듈 추가
    s.dependency 'KakaoSDKCommon', kakao_sdk_version  # 필수 요소를 담은 공통 모듈
    s.dependency 'KakaoSDKAuth', kakao_sdk_version  # 사용자 인증
    s.dependency 'KakaoSDKUser', kakao_sdk_version  # 카카오 로그인, 사용자 관리
    s.dependency 'KakaoSDKTalk', kakao_sdk_version  # 친구, 메시지(카카오톡)
    s.dependency 'KakaoSDKShare', kakao_sdk_version  # 메시지(카카오톡 공유)
    s.dependency 'KakaoSDKFriend', kakao_sdk_version # 카카오톡 소셜 피커, 리소스 번들 파일 포함

  end
end
