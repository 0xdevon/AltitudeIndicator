# AltitudeIndicator

AltitudeIndicator is a compact SwiftUI iOS app for checking real-time altitude, coordinates, location accuracy, heading, and movement data. The app display name is `见山`.

It is designed for hiking, outdoor photography scouting, route checking, and everyday situations where you want a clean view of your current elevation and position.

## Features

- Automatically requests location permission when the app opens and starts measuring after authorization.
- Shows current altitude in real time.
- Prefers `CMAltimeter` absolute altitude when available, then falls back to `CLLocation` altitude.
- Displays latitude and longitude in decimal degrees or DMS format.
- Shows horizontal accuracy, vertical accuracy, speed, heading, and course.
- Supports meters and feet.
- Copies the current coordinate pair to the clipboard.
- Supports system, light, and dark appearance modes.
- Uses SwiftUI, CoreLocation, CoreMotion, and UIKit without third-party dependencies.

## Altitude Data

AltitudeIndicator uses two altitude sources:

1. `CMAltimeter` absolute altitude from CoreMotion, when supported by the device and allowed by system permissions.
2. `CLLocation.altitude` from CoreLocation as a fallback when absolute altitude is unavailable, restricted, or running in an environment without barometer data.

The UI shows the current altitude source so you can tell whether the reading comes from the barometer-based absolute altitude stream or location altitude.

## Requirements

- Xcode with iOS development support
- iOS 17.0 or later
- SwiftUI
- CoreLocation
- CoreMotion
- UIKit
- A physical iPhone is recommended for accurate altitude and heading tests

## Project Info

- Xcode project: `AltitudeIndicator.xcodeproj`
- Target and scheme: `AltitudeIndicator`
- App display name: `见山`
- Bundle identifier: `com.devonchan.AltitudeIndicator`
- Version: `1.0.0 (1)`
- Supported platforms: iPhone and iPad on iOS / iOS Simulator

## Setup

1. Open `AltitudeIndicator.xcodeproj` in Xcode.
2. Select the `AltitudeIndicator` target.
3. In Signing & Capabilities, choose your development team.
4. If needed, change the bundle identifier to a unique value, for example `com.yourname.AltitudeIndicator`.
5. Run the app on an iPhone or iOS Simulator.
6. Grant location permission when prompted.

## Permissions

The project configures the following usage descriptions in build settings:

- `NSLocationWhenInUseUsageDescription`: used to display altitude, coordinates, direction, and location accuracy.
- `NSMotionUsageDescription`: used to read barometer-based altitude for readings closer to the system Compass app.

Background location is not configured. If you add background location later, also configure Background Modes and the required Always location usage descriptions.

## Testing Notes

- Real altitude readings should be tested on a physical device, preferably outdoors with an open sky view.
- Simulator location and altitude depend on Xcode's simulated location data.
- Barometer-based absolute altitude may not be available on all devices, in all permission states, or in the simulator.
- GPS, barometer calibration, network conditions, and terrain obstruction can all affect accuracy.

---

# AltitudeIndicator 中文说明

AltitudeIndicator 是一个简洁的 SwiftUI iOS App，用于实时查看海拔、经纬度、定位精度、航向与运动数据。App 的显示名称为 `见山`。

它适合徒步、摄影踩点、路线确认，以及日常出行中快速查看当前位置和海拔。

## 功能

- App 打开后自动请求定位权限，授权后开始测量。
- 实时显示当前位置海拔。
- 优先使用 `CMAltimeter` 绝对海拔；不可用时回退到 `CLLocation` 定位海拔。
- 支持十进制与度分秒两种经纬度格式。
- 显示水平精度、垂直精度、速度、航向和行进方向。
- 支持米和英尺单位切换。
- 支持一键复制当前坐标。
- 支持跟随系统、浅色和深色外观模式。
- 使用 SwiftUI、CoreLocation、CoreMotion 和 UIKit，无第三方依赖。

## 海拔数据来源

AltitudeIndicator 使用两类海拔数据：

1. 设备支持且权限允许时，使用 CoreMotion 的 `CMAltimeter` 绝对海拔。
2. 当绝对海拔不可用、受限，或运行环境没有气压计数据时，回退到 CoreLocation 的 `CLLocation.altitude`。

界面会显示当前海拔来源，方便判断读数来自气压计绝对海拔还是定位海拔。

## 环境要求

- 安装支持 iOS 开发的 Xcode
- iOS 17.0 或更高版本
- SwiftUI
- CoreLocation
- CoreMotion
- UIKit
- 建议使用 iPhone 真机测试，以获得更可靠的海拔和航向数据

## 项目信息

- Xcode 工程：`AltitudeIndicator.xcodeproj`
- Target / Scheme：`AltitudeIndicator`
- App 显示名称：`见山`
- Bundle Identifier：`com.devonchan.AltitudeIndicator`
- 版本：`1.0.0 (1)`
- 支持平台：iPhone 和 iPad，支持 iOS 真机与 iOS Simulator

## 运行方式

1. 使用 Xcode 打开 `AltitudeIndicator.xcodeproj`。
2. 选择 `AltitudeIndicator` target。
3. 在 Signing & Capabilities 中选择你的开发团队。
4. 如有需要，将 Bundle Identifier 修改为唯一值，例如 `com.yourname.AltitudeIndicator`。
5. 运行到 iPhone 真机或 iOS Simulator。
6. 首次打开时允许定位权限。

## 权限说明

项目已在 Build Settings 中配置以下权限说明：

- `NSLocationWhenInUseUsageDescription`：用于显示海拔、经纬度、方向和定位精度。
- `NSMotionUsageDescription`：用于读取气压计海拔，以提供更接近系统指南针的海拔高度。

项目目前未配置后台定位。如果后续增加后台定位，需要额外配置 Background Modes 与 Always 定位权限说明。

## 测试说明

- 真实海拔建议在 iPhone 真机、户外开阔环境中测试。
- 模拟器的位置和海拔数据依赖 Xcode 的模拟定位。
- 气压计绝对海拔并非在所有设备、权限状态或模拟器环境中都可用。
- GPS、气压计校准、网络环境和地形遮挡都会影响读数精度。
