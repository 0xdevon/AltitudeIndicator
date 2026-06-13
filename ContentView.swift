import SwiftUI
import CoreLocation
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ContentView: View {
    @StateObject private var locationProvider = LocationProvider()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("altitudeUnit") private var altitudeUnitRaw = AltitudeUnit.meters.rawValue
    @AppStorage("coordinateDisplayMode") private var coordinateDisplayModeRaw = CoordinateDisplayMode.decimal.rawValue
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showCopiedToast = false
    @State private var toastMessage = "坐标已复制"

    private var altitudeUnit: AltitudeUnit {
        get { AltitudeUnit(rawValue: altitudeUnitRaw) ?? .meters }
        nonmutating set { altitudeUnitRaw = newValue.rawValue }
    }

    private var coordinateDisplayMode: CoordinateDisplayMode {
        get { CoordinateDisplayMode(rawValue: coordinateDisplayModeRaw) ?? .decimal }
        nonmutating set { coordinateDisplayModeRaw = newValue.rawValue }
    }

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        nonmutating set { appearanceModeRaw = newValue.rawValue }
    }

    private var toastBackground: Color {
        colorScheme == .dark
            ? Color(.secondarySystemGroupedBackground).opacity(0.9)
            : Color(.secondarySystemGroupedBackground)
    }

    private var toastBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.06)
    }

    private var toastShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.28)
            : Color.black.opacity(0.08)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradient()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        headerCard
                        altitudeCard
                        coordinateCard
                        accuracySection
                        movementSection
                        footerNote
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("见山")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    aboutMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    settingsMenu
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    Text(toastMessage)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(toastBackground, in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(toastBorder, lineWidth: 1)
                        }
                        .shadow(color: toastShadow, radius: 8, x: 0, y: 4)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                locationProvider.start()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    locationProvider.start()
                }
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private var aboutMenu: some View {
        Menu {
            Section("关于") {
                Button {
                } label: {
                    Label("见山", systemImage: "app")
                }
                .disabled(true)

                Button {
                } label: {
                    Label("版本 \(appVersionText)", systemImage: "number")
                }
                .disabled(true)
            }

            Section {
                Button {
                    openFeedback()
                } label: {
                    Label("意见反馈", systemImage: "envelope")
                }
            }
        } label: {
            Image(systemName: "info.circle")
        }
        .accessibilityLabel("关于 App")
    }

    private var settingsMenu: some View {
        Menu {
            Picker("高度单位", selection: Binding(
                get: { altitudeUnit },
                set: { altitudeUnit = $0 }
            )) {
                ForEach(AltitudeUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }

            Picker("坐标格式", selection: Binding(
                get: { coordinateDisplayMode },
                set: { coordinateDisplayMode = $0 }
            )) {
                ForEach(CoordinateDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Picker("外观模式", selection: Binding(
                get: { appearanceMode },
                set: { appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("显示设置")
    }

    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Text("实时海拔 · 经纬度")
                        .font(.title2.bold())
                    Spacer()
                    StatusPill(text: locationProvider.statusText, isActive: locationProvider.isUpdating)
                }

                Text("简洁显示当前位置、海拔、定位精度与航向，适合徒步、摄影踩点和日常出行。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let error = locationProvider.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if locationProvider.authorizationStatus == .notDetermined {
                    Label("首次打开会自动请求定位权限，授权后立即开始测量。", systemImage: "location.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if !locationProvider.canUseLocation {
                    ActionButton(title: "打开系统设置", systemImage: "gearshape.fill") {
                        openSettings()
                    }
                } else {
                    Label("App 打开后自动持续测量，无需手动开始。", systemImage: "dot.radiowaves.left.and.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var altitudeCard: some View {
        GlassCard(cornerRadius: 34) {
            VStack(spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(LocationFormatter.altitude(locationProvider.currentAltitudeReading, unit: altitudeUnit))
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(LocationFormatter.altitudeUnitSymbol(altitudeUnit))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text("当前海拔")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        altitudeAccuracyLabel
                        Spacer(minLength: 8)
                        altitudeSourceLabel
                        Spacer(minLength: 8)
                        altitudeUpdatedLabel
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        altitudeAccuracyLabel
                        altitudeSourceLabel
                        altitudeUpdatedLabel
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var coordinateCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("坐标", systemImage: "mappin.and.ellipse")
                        .font(.headline)
                    Spacer()
                    Button {
                        copyCoordinate()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .disabled(locationProvider.currentLocation == nil)
                }

                VStack(spacing: 10) {
                    infoRow(title: "纬度", value: LocationFormatter.latitude(locationProvider.currentLocation?.coordinate, mode: coordinateDisplayMode))
                    infoRow(title: "经度", value: LocationFormatter.longitude(locationProvider.currentLocation?.coordinate, mode: coordinateDisplayMode))
                }
            }
        }
    }

    private var accuracySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            MetricTile(
                title: "水平精度",
                value: LocationFormatter.accuracy(locationProvider.currentLocation?.horizontalAccuracy ?? -1, unit: altitudeUnit),
                subtitle: "越小越准确",
                icon: "scope"
            )
            MetricTile(
                title: "垂直精度",
                value: LocationFormatter.accuracy(locationProvider.currentAltitudeReading?.accuracy ?? -1, unit: altitudeUnit),
                subtitle: "海拔可信度",
                icon: "arrow.up.and.down.circle"
            )
        }
    }

    private var altitudeAccuracyLabel: some View {
        Label("垂直精度 \(LocationFormatter.accuracy(locationProvider.currentAltitudeReading?.accuracy ?? -1, unit: altitudeUnit))", systemImage: "scope")
    }

    private var altitudeSourceLabel: some View {
        Label(LocationFormatter.altitudeSource(locationProvider.currentAltitudeReading), systemImage: "barometer")
    }

    private var altitudeUpdatedLabel: some View {
        Label(locationProvider.lastUpdatedText, systemImage: "clock")
    }

    private var movementSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("运动与方向", systemImage: "safari")
                        .font(.headline)
                    Spacer()
                    Text(LocationFormatter.directionName(headingDegrees))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 18) {
                    CompassDial(degrees: headingDegrees)
                    VStack(alignment: .leading, spacing: 16) {
                        infoRow(title: "航向", value: LocationFormatter.heading(locationProvider.currentHeading))
                        infoRow(title: "行进方向", value: LocationFormatter.course(locationProvider.currentLocation?.course ?? -1))
                        infoRow(title: "速度", value: LocationFormatter.speed(locationProvider.currentLocation?.speed ?? -1))
                    }
                }
            }
        }
    }

    private var footerNote: some View {
        Text("提示：海拔数据受 GPS、气压计、网络环境与地形遮挡影响，户外开阔区域通常更准确。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var headingDegrees: Double? {
        if let heading = locationProvider.currentHeading {
            return heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        }
        if let course = locationProvider.currentLocation?.course, course >= 0 {
            return course
        }
        return nil
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private func copyCoordinate() {
        guard let coordinate = locationProvider.currentLocation?.coordinate else { return }
        let value = LocationFormatter.coordinatePair(coordinate, mode: coordinateDisplayMode)
        UIPasteboard.general.string = value
        showToast("坐标已复制")
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func openFeedback() {
        let subject = "见山意见反馈"
        let body = """


设备：
系统版本：
问题或建议：
"""
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "i@devonchan.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else { return }

        UIApplication.shared.open(url) { success in
            if !success {
                UIPasteboard.general.string = "\(subject)\n\(body)"
                showToast("反馈内容已复制")
            }
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showCopiedToast = false
            }
        }
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
