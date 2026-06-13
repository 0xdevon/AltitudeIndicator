import Foundation
import CoreLocation

extension UnitLength {
    static let foot = UnitLength.feet
}

enum AltitudeUnit: String, CaseIterable, Identifiable {
    case meters
    case feet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meters: return "米"
        case .feet: return "英尺"
        }
    }
}

enum CoordinateDisplayMode: String, CaseIterable, Identifiable {
    case decimal
    case dms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .decimal: return "十进制"
        case .dms: return "度分秒"
        }
    }
}

struct LocationFormatter {
    static func altitude(_ reading: AltitudeReading?, unit: AltitudeUnit) -> String {
        guard let reading else { return "—" }
        return formattedAltitude(reading.altitude, unit: unit)
    }

    static func altitude(_ location: CLLocation?, unit: AltitudeUnit) -> String {
        guard let altitude = location?.altitude else { return "—" }
        return formattedAltitude(altitude, unit: unit)
    }

    private static func formattedAltitude(_ altitude: CLLocationDistance, unit: AltitudeUnit) -> String {
        switch unit {
        case .meters:
            return String(format: "%.1f", altitude)
        case .feet:
            return String(format: "%.1f", altitude * 3.280839895)
        }
    }

    static func altitudeUnitSymbol(_ unit: AltitudeUnit) -> String {
        switch unit {
        case .meters: return "m"
        case .feet: return "ft"
        }
    }

    static func altitudeSource(_ reading: AltitudeReading?) -> String {
        reading?.source.title ?? "等待数据"
    }

    static func accuracy(_ value: CLLocationAccuracy, unit: AltitudeUnit) -> String {
        guard value >= 0 else { return "未知" }
        switch unit {
        case .meters:
            return String(format: "±%.1f m", value)
        case .feet:
            return String(format: "±%.1f ft", value * 3.280839895)
        }
    }

    static func coordinatePair(_ coordinate: CLLocationCoordinate2D?, mode: CoordinateDisplayMode) -> String {
        guard let coordinate else { return "—" }
        switch mode {
        case .decimal:
            return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
        case .dms:
            return "\(dms(coordinate.latitude, positive: "N", negative: "S"))  \(dms(coordinate.longitude, positive: "E", negative: "W"))"
        }
    }

    static func latitude(_ coordinate: CLLocationCoordinate2D?, mode: CoordinateDisplayMode) -> String {
        guard let coordinate else { return "—" }
        switch mode {
        case .decimal:
            return String(format: "%.6f°", coordinate.latitude)
        case .dms:
            return dms(coordinate.latitude, positive: "N", negative: "S")
        }
    }

    static func longitude(_ coordinate: CLLocationCoordinate2D?, mode: CoordinateDisplayMode) -> String {
        guard let coordinate else { return "—" }
        switch mode {
        case .decimal:
            return String(format: "%.6f°", coordinate.longitude)
        case .dms:
            return dms(coordinate.longitude, positive: "E", negative: "W")
        }
    }

    static func speed(_ speed: CLLocationSpeed) -> String {
        guard speed >= 0 else { return "—" }
        return String(format: "%.1f km/h", speed * 3.6)
    }

    static func course(_ course: CLLocationDirection) -> String {
        guard course >= 0 else { return "—" }
        return String(format: "%.0f°", course)
    }

    static func heading(_ heading: CLHeading?) -> String {
        guard let heading else { return "—" }
        let value = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        return String(format: "%.0f°", value)
    }

    static func directionName(_ degrees: CLLocationDirection?) -> String {
        guard let degrees, degrees >= 0 else { return "未知" }
        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let index = Int((degrees + 22.5) / 45.0) % directions.count
        return directions[index]
    }

    private static func dms(_ value: Double, positive: String, negative: String) -> String {
        let direction = value >= 0 ? positive : negative
        let absolute = abs(value)
        let degrees = Int(absolute)
        let minutesFull = (absolute - Double(degrees)) * 60
        let minutes = Int(minutesFull)
        let seconds = (minutesFull - Double(minutes)) * 60
        return String(format: "%d°%02d′%05.2f″ %@", degrees, minutes, seconds, direction)
    }
}
