import Foundation

public func convertToYYMMDD(from input: String?) -> String {
    if let input = input, !input.isEmpty {
        let parts = input.split(separator: ".")
        if parts.count == 3,
           let day = parts.first,
           let month = parts.dropFirst().first,
           let year = parts.last,
           year.count == 4 {
            let yy = year.suffix(2)
            return "\(yy)\(month)\(day)"
        }
    }
    // Fallback to current date
    let now = Date()
    let calendar = Calendar.current
    let year = calendar.component(.year, from: now) % 100
    let month = calendar.component(.month, from: now)
    let day = calendar.component(.day, from: now)
    return String(format: "%02d%02d%02d", year, month, day)
}
