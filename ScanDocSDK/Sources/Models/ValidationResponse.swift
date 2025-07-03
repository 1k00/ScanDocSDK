struct ValidationResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case infoCode = "InfoCode"
        case validated = "Validated"
        case side = "Side"
        case country = "Country"
        case detectedBlurValue = "DetectedBlurValue"
    }

    let infoCode: String
    let validated: Bool?
    let side: ValidationSideResponse?
    let country: String?
    let detectedBlurValue: Double?
}

enum ValidationSideResponse: String, Decodable {

    case front
    case back
    case unknown

    init?(rawValue: String) {
        switch rawValue.uppercased() {
        case "FRONT":
            self = .front
        case "BACK":
            self = .back
        default:
            self = .unknown
        }
    }
}
