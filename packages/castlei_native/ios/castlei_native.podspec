Pod::Spec.new do |s|
  s.name = 'castlei_native'
  s.version = '1.0.0'
  s.summary = 'Castlei Stockfish native adapter'
  s.description = 'Pinned Stockfish with an application-owned C ABI and private UCI queues.'
  s.homepage = 'https://stockfishchess.org'
  s.license = { :file => '../../../LICENSE', :type => 'GPL-3.0' }
  s.author = { 'Castlei' => 'Castlei' }
  s.source = { :path => '.' }
  s.source_files = '../../../native/adapter.cpp', '../../../native/stockfish/src/**/*.{h,cpp}'
  s.exclude_files = '../../../native/stockfish/src/main.cpp'
  s.preserve_paths = '../../../native/stockfish/src/*.nnue'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/../../../native/stockfish/src"',
    'OTHER_CPLUSPLUSFLAGS' => '$(inherited) -O3',
    'DEFINES_MODULE' => 'YES'
  }
end
