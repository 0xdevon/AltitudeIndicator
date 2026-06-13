import Foundation
import CoreLocation
import CoreMotion
import Combine

struct AltitudeReading {
    enum Source {
        case absoluteAltimeter
        case location

        var title: String {
            switch self {
            case .absoluteAltimeter:
                return "气压计海拔"
            case .location:
                return "定位海拔"
            }
        }
    }

    let altitude: CLLocationDistance
    let accuracy: CLLocationAccuracy
    let timestamp: Date
    let source: Source
}

final class LocationProvider: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private let altimeterQueue = OperationQueue()
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.unitsStyle = .short
        return formatter
    }()
    private var isAbsoluteAltitudeUpdating = false

    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var currentAltitudeReading: AltitudeReading?
    @Published var isUpdating = false
    @Published var errorMessage: String?
    @Published var lastUpdatedText = "尚未更新"

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
        altimeterQueue.qualityOfService = .userInitiated
    }

    var canUseLocation: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var statusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "等待授权"
        case .restricted:
            return "定位受限"
        case .denied:
            return "定位已关闭"
        case .authorizedAlways, .authorizedWhenInUse:
            return isUpdating ? "实时更新中" : "已授权"
        @unknown default:
            return "未知状态"
        }
    }

    func requestPermission() {
        errorMessage = nil
        manager.requestWhenInUseAuthorization()
    }

    /// App 打开或回到前台时调用。
    /// 不再在主线程调用 CLLocationManager.locationServicesEnabled()，
    /// 而是优先根据 authorizationStatus 决定下一步，并等待
    /// locationManagerDidChangeAuthorization(_:) 回调后启动定位。
    func start() {
        errorMessage = nil
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingServices()
        case .denied:
            stop()
            errorMessage = "定位权限未开启，请在系统设置中允许本 App 使用位置权限。"
        case .restricted:
            stop()
            errorMessage = "当前设备或系统策略限制了定位服务。"
        @unknown default:
            stop()
            errorMessage = "未知定位权限状态，请检查系统设置。"
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        stopAbsoluteAltitudeUpdates()
        isUpdating = false
    }

    func refreshOnce() {
        errorMessage = nil
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            errorMessage = "定位权限未开启，请在系统设置中允许本 App 使用位置权限。"
        case .restricted:
            errorMessage = "当前设备或系统策略限制了定位服务。"
        @unknown default:
            errorMessage = "未知定位权限状态，请检查系统设置。"
        }
    }

    private func startUpdatingServices() {
        if !isUpdating {
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
            isUpdating = true
        }
        startAbsoluteAltitudeUpdatesIfAvailable()
    }

    private func startAbsoluteAltitudeUpdatesIfAvailable() {
        guard !isAbsoluteAltitudeUpdating else { return }
        guard CMAltimeter.isAbsoluteAltitudeAvailable() else { return }

        let status = CMAltimeter.authorizationStatus()
        guard status != .denied && status != .restricted else { return }

        isAbsoluteAltitudeUpdating = true
        altimeter.startAbsoluteAltitudeUpdates(to: altimeterQueue) { [weak self] altitudeData, error in
            guard let self else { return }

            if error != nil {
                DispatchQueue.main.async {
                    self.stopAbsoluteAltitudeUpdates()
                }
                return
            }

            guard let altitudeData else { return }
            let now = Date()
            DispatchQueue.main.async {
                guard self.shouldPublishAltitude(
                    altitude: altitudeData.altitude,
                    accuracy: altitudeData.accuracy,
                    timestamp: now,
                    source: .absoluteAltimeter
                ) else { return }

                self.currentAltitudeReading = AltitudeReading(
                    altitude: altitudeData.altitude,
                    accuracy: altitudeData.accuracy,
                    timestamp: now,
                    source: .absoluteAltimeter
                )
                self.updateLastUpdatedText(from: now)
                self.errorMessage = nil
            }
        }
    }

    private func stopAbsoluteAltitudeUpdates() {
        guard isAbsoluteAltitudeUpdating else { return }
        altimeter.stopAbsoluteAltitudeUpdates()
        isAbsoluteAltitudeUpdating = false
    }

    private func updateLastUpdatedText(from date: Date) {
        guard abs(Date().timeIntervalSince(date)) >= 1 else {
            lastUpdatedText = "刚刚"
            return
        }

        lastUpdatedText = Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    private func shouldPublishLocation(_ location: CLLocation) -> Bool {
        guard let currentLocation else { return true }

        let elapsed = abs(location.timestamp.timeIntervalSince(currentLocation.timestamp))
        let distance = location.distance(from: currentLocation)
        let altitudeDelta = abs(location.altitude - currentLocation.altitude)
        let speedDelta = abs(location.speed - currentLocation.speed)
        let courseDelta = abs(normalizedAngleDifference(location.course, currentLocation.course))

        return elapsed >= 1
            || distance >= 1
            || altitudeDelta >= 0.5
            || speedDelta >= 0.2
            || courseDelta >= 1
            || abs(location.horizontalAccuracy - currentLocation.horizontalAccuracy) >= 1
            || abs(location.verticalAccuracy - currentLocation.verticalAccuracy) >= 1
    }

    private func shouldPublishAltitude(
        altitude: CLLocationDistance,
        accuracy: CLLocationAccuracy,
        timestamp: Date,
        source: AltitudeReading.Source
    ) -> Bool {
        guard let currentAltitudeReading else { return true }

        return currentAltitudeReading.source != source
            || abs(timestamp.timeIntervalSince(currentAltitudeReading.timestamp)) >= 1
            || abs(altitude - currentAltitudeReading.altitude) >= 0.25
            || abs(accuracy - currentAltitudeReading.accuracy) >= 0.5
    }

    private func shouldPublishHeading(_ heading: CLHeading) -> Bool {
        guard let currentHeading else { return true }

        let newHeading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        let oldHeading = currentHeading.trueHeading >= 0 ? currentHeading.trueHeading : currentHeading.magneticHeading

        return abs(normalizedAngleDifference(newHeading, oldHeading)) >= 1
            || abs(heading.headingAccuracy - currentHeading.headingAccuracy) >= 5
            || abs(heading.timestamp.timeIntervalSince(currentHeading.timestamp)) >= 2
    }

    private func normalizedAngleDifference(_ lhs: CLLocationDirection, _ rhs: CLLocationDirection) -> CLLocationDirection {
        guard lhs >= 0 || rhs >= 0 else { return 0 }
        guard lhs >= 0, rhs >= 0 else { return .greatestFiniteMagnitude }

        let difference = (lhs - rhs).truncatingRemainder(dividingBy: 360)
        if difference > 180 {
            return difference - 360
        } else if difference < -180 {
            return difference + 360
        } else {
            return difference
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            startUpdatingServices()
        case .notDetermined:
            break
        case .denied:
            stop()
            errorMessage = "定位权限未开启，请在系统设置中允许本 App 使用位置权限。"
        case .restricted:
            stop()
            errorMessage = "当前设备或系统策略限制了定位服务。"
        @unknown default:
            stop()
            errorMessage = "未知定位权限状态，请检查系统设置。"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        guard shouldPublishLocation(latest) else { return }

        currentLocation = latest
        if currentAltitudeReading?.source != .absoluteAltimeter || !isAbsoluteAltitudeUpdating {
            currentAltitudeReading = AltitudeReading(
                altitude: latest.altitude,
                accuracy: latest.verticalAccuracy,
                timestamp: latest.timestamp,
                source: .location
            )
            updateLastUpdatedText(from: latest.timestamp)
        }
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        guard shouldPublishHeading(newHeading) else { return }
        currentHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            errorMessage = "暂时无法获取当前位置，请保持 App 打开并移动到开阔区域。"
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
