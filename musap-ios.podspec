Pod::Spec.new do |s|
  s.name         = 'musap-ios'
  s.version      = '0.1.0'
  s.summary      = 'musap-ios module'
  s.description  = <<-DESC
                   musap-ios pod
                   DESC
  s.homepage     = 'https://github.com/methics/musap-ios'
  s.license      = { :type => 'Apache, :file => 'LICENSE' }
  s.author       = { 'Author Name' => 'support@methics.fi' }
  s.source       = { :git => 'https://github.com/methics/musap-ios.git', :tag => s.version.to_s }

  s.platform     = :ios, '15.0'
  s.source_files = 'Sources/**/*.{swift,h,m,mm}'
  s.module_name  = 'musap_ios'

  s.dependency 'YubiKit'
end
