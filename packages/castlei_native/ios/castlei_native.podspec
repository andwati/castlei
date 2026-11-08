Pod::Spec.new do |s|
  s.name = 'castlei_native'
  s.version = '1.0.0'
  s.summary = 'Castlei Stockfish native adapter'
  s.description = 'Pinned Stockfish with an application-owned C ABI and private UCI queues.'
  s.homepage = 'https://stockfishchess.org'
  s.license = { :file => '../../../LICENSE', :type => 'GPL-3.0' }
  s.author = { 'Castlei' => 'Castlei' }
  s.source = { :path => '.' }
  # Forwarder files include the real sources in place (CocoaPods cannot reliably
  # glob outside the pod directory). Regenerate with tool/gen_ios_forwarders.sh.
  s.source_files = 'Classes/**/*.{cpp,h}'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES',
    'GCC_ENABLE_CPP_RTTI' => 'YES',
    # The embedded NNUE networks are pulled in with .incbin, resolved via this path.
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/../../../native/stockfish/src"',
    'OTHER_CPLUSPLUSFLAGS' => '$(inherited) -O3 -fexceptions -frtti',
    'DEFINES_MODULE' => 'YES'
  }
end
