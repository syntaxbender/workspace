```
brew install openjdk@17
brew install --cask android-commandlinetools
brew install --cask android-platform-tools
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk
cat >> ~/.zshrc <<'EOF'

# Java 17
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
EOF
cat >> ~/.zshrc <<'EOF'

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
EOF

source ~/.zshrc
sdkmanager --sdk_root="$ANDROID_HOME" --licenses
sdkmanager --update
sdkmanager --list
sdkmanager --sdk_root="$ANDROID_HOME" \
  "cmdline-tools;latest" \
  "platform-tools" \
  "emulator" \
  "platforms;android-36" \
  "build-tools;36.1.0" \
  "system-images;android-36;google_apis_playstore;arm64-v8a"
sdkmanager --sdk_root="$ANDROID_HOME" --list_installed

avdmanager create avd \
  -n Pixel_8_API_36 \
  -k "system-images;android-36;google_apis_playstore;arm64-v8a" \
  -d pixel_8
  
avdmanager list avd\nemulator -list-avds

emulator @Pixel_8_API_36 \
  -no-snapshot-load \
  -no-boot-anim
```
