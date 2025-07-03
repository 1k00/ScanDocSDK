import Foundation

struct ExtractionRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case acceptTermsAndConditions = "AcceptTermsAndConditions"
        case dataFields = "DataFields"
        case settings = "Settings"
    }

    let acceptTermsAndConditions: Bool
    let dataFields: ExtractionDataFieldsRequest
    let settings: ExtractionSettingsRequest
}

struct ExtractionDataFieldsRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case frontImage = "FrontImage"
        case frontImageType = "FrontImageType"
        case frontImageCropped = "FrontImageCropped"
        case backImage = "BackImage"
        case backImageType = "BackImageType"
        case backImageCropped = "BackImageCropped"
    }

    let frontImage: String?
    let frontImageType: String?
    let frontImageCropped: Bool?
    let backImage: String?
    let backImageType: String?
    let backImageCropped: Bool?
}

struct ExtractionSettingsRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case ignoreBackImage = "IgnoreBackImage"
        case shouldReturnDocumentImage = "ShouldReturnDocumentImage"
        case shouldReturnFaceIfDetected = "ShouldReturnFaceIfDetected"
        case shouldReturnSignatureIfDetected = "ShouldReturnSignatureIfDetected"
        case skipDocumentsSizeCheck = "SkipDocumentsSizeCheck"
        case skipImageSizeCheck = "SkipImageSizeCheck"
        case canStoreImages = "CanStoreImages"
        case enforceDocsSameCountryTypeSeries = "EnforceDocsSameCountryTypeSeries"
        case caseSensitiveOutput = "CaseSensitiveOutput"
        case faceImageResize = "FaceImageResize"
        case signatureImageResize = "SignatureImageResize"
        case segmentedImageResize = "SegmentedImageResize"
        case storeFaceImage = "StoreFaceImage"
        case dontUseValidation = "DontUseValidation"
    }

    let ignoreBackImage: Bool
    let shouldReturnDocumentImage: Bool
    let shouldReturnFaceIfDetected: Bool
    let shouldReturnSignatureIfDetected: Bool
    let skipDocumentsSizeCheck: Bool
    let skipImageSizeCheck: Bool
    let canStoreImages: Bool
    let enforceDocsSameCountryTypeSeries: Bool
    let caseSensitiveOutput: Bool
    let faceImageResize: String?
    let signatureImageResize: String?
    let segmentedImageResize: String?
    let storeFaceImage: Bool
    let dontUseValidation: Bool
}
