project 'MyStudies.xcodeproj/'

# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
platform :ios, '13.0'

# Pods for FDA
def main_pods

  pod 'IQKeyboardManagerSwift'
  pod 'SlideMenuControllerSwift', :git => 'https://github.com/AtomicSLLC/SlideMenuControllerSwift.git', :branch => 'swift5'
  pod 'SDWebImage'
  pod 'RealmSwift', '5.5.1'
  pod 'CryptoSwift'
  pod 'ActionSheetPicker-3.0'
  pod 'Toast-Swift'
  pod 'ReachabilitySwift'
  pod 'Alamofire'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
end

target 'MyStudies' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  main_pods

end

target 'Bubs' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  main_pods
end

target 'Validcare' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  main_pods
end

target 'ValidcareQA' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  main_pods
end


target 'MyStudiesTests' do
  use_frameworks!
  inherit! :search_paths
  pod 'Mockingjay', '3.0.0-alpha.1'
end
