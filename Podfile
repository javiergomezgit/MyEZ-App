# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end

target 'MyEZ' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyEZ
  #pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  #pod 'Firebase/InAppMessagingDisplay'

  pod 'NVActivityIndicatorView'
  pod 'IQKeyboardManagerSwift'
  pod 'SCLAlertView'
  pod 'lottie-ios'
  pod 'SwiftyJSON'
  pod 'YPImagePicker'
  pod 'Kingfisher', '~> 8.0'
end
