# customview-swift-ios
Vidyo.io Swift iOS app featuring ability to switch between composited and custom layouts. This app shows how to integrate your swift project with Vidyo.io. It also shows how to use custom layout option where you can choose to display each remote participant seperately. 

## Clone Repository
git clone https://github.com/Vidyo/customview-swift-ios.git

## Acquire Framework
1. Download the latest Vidyo.io iOS SDK package: https://static.vidyo.io/latest/package/VidyoClient-iOSSDK.zip
2. Copy the framework located at VidyoClient-iOSSDK/lib/ios/VidyoClientIOS.framework to the CustomLayoutSample directory under where this repository was cloned.

> Note: VidyoClient SDK version 4.1.22.9 or greater is required.
> The version of the SDK that you are acquiring is highlighted in the blue box here: https://developer.vidyo.io/documentation/latest

## Build and Run Application
1. Open the project CustomLayoutSample.xcodeproj in Xcode 8.0 or later.
2. Replace the "VIDYO_TOKEN" variable with an actual valid token. 
3. Connect an iOS device to your computer via USB.
4. Select the iOS device as the build target of your application.
5. Build and run the application on the iOS device.
