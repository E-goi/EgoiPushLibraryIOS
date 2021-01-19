#
# Be sure to run `pod lib lint EgoiPushLibrary.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "EgoiPushLibrary"
  s.version          = "1.0.7"
  s.summary          = "E-goi's Push Notification Library."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This library is responsible for handling all matter related to Push Notifications received from E-goi.
                       DESC

  s.homepage         = "https://github.com/JoaoCGS/EgoiPushLibrary"
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "João Silva" => "jsilva@e-goi.com" }
  s.source           = { :git => "https://github.com/JoaoCGS/EgoiPushLibrary.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = "12.0"
  
  s.swift_version = "5.0"

  s.source_files = "EgoiPushLibrary/Classes/**/*"
  
  # s.resource_bundles = {
  #   'EgoiPushLibrary' => ['EgoiPushLibrary/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.libraries = "Firebase", "FirebaseCore", "FirebaseCoreDialog", "FirebaseInstalations", "FirebaseInstanceID", "FirebaseMessaging", "GoogleDataTransport", "GoogleUtilities", "nanopb", "FBLPromises"
  s.frameworks = "UIKit"
end
