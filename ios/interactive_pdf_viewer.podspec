Pod::Spec.new do |s|
  s.name             = 'interactive_pdf_viewer'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin for viewing PDFs using native iOS PDFKit.'
  s.description      = <<-DESC
A Flutter plugin that allows viewing PDF files using the native iOS PDFKit framework.
                       DESC
  s.homepage         = 'https://github.com/bjorndonald/interactive_pdf_viewer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bjorn-Donald Bassey' => 'bjorndonaldb@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end