import Foundation

struct ValidationRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case acceptTermsAndConditions = "AcceptTermsAndConditions"
        case dataFields = "DataFields"
    }

    let acceptTermsAndConditions: Bool
    let dataFields: ValidationDataFieldsRequest
}

struct ValidationDataFieldsRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case images = "Images"
        case blurValues = "BlurValues"
    }

    let images: [String]
    let blurValues: [Double]
}
