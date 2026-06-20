brew install aria2
brew install mas
mas install 497799835
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
open -a Xcode
xcrun simctl list runtimes
xcodebuild -downloadPlatform iOS
xcrun simctl list devicetypes
xcrun simctl create "iPhone 17 Pro RN" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-26-5
xcrun simctl list devices
xcrun simctl boot <device-id>
open -a Simulator
