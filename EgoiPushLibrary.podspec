Pod::Spec.new do |s|
  s.name             = "EgoiPushLibrary"
  s.version          = "2.2.0"
  s.summary          = "E-goi's Push Notification Library."

  s.description      = <<-DESC
  This library is responsible for handling all matter related to Push Notifications received from E-goi.
                       DESC

  s.homepage         = "https://github.com/E-goi/EgoiPushLibraryIOS"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "E-goi" => "integrations@e-goi.com" }
  s.source           = { :git => "https://github.com/E-goi/EgoiPushLibraryIOS.git", :tag => s.version.to_s }

  s.ios.deployment_target = "12.0"
  
  s.swift_version = "5.0"

  s.source_files = "EgoiPushLibrary/Classes/**/*"
  
  s.frameworks = "UIKit"
end
