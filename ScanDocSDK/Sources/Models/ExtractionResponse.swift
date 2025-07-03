import Foundation

struct ExtractionResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case infoCode = "InfoCode"
        case errors = "Errors"
        case warnings = "Warnings"
        case data = "Data"
        case imageData = "ImageData"
    }

    let infoCode: String?
    let errors: [String]?
    let warnings: [String]?
    let data: ExtractionDataResponse?
    let imageData: ExtractionImageDataResponse?
}

struct ExtractionDataResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case surname = "Surname"
        case birthDate = "BirthDate"
        case gender = "Gender"
        case placeOfBirth = "PlaceOfBirth"
        case nationality = "Nationality"
        case documentNumber = "DocumentNumber"
        case issuedDate = "IssuedDate"
        case expiryDate = "ExpiryDate"
        case countryOfIssue = "CountryOfIssue"
        case issuingAuthority = "IssuingAuthority"
        case addressCountry = "AddressCountry"
        case addressZip = "AddressZip"
        case addressCity = "AddressCity"
        case addressCounty = "AddressCounty"
        case addressStreet = "AddressStreet"
        case personalIdentificationNumber = "PersonalIdentificationNumber"
        case givenName = "GivenName"
        case familyName = "FamilyName"
        case mothersGivenName = "MothersGivenName"
        case mothersFamilyName = "MothersFamilyName"
        case secondLastName = "SecondLastName"
        case address = "Address"
        case placeOfIssue = "PlaceOfIssue"
        case fathersGivenName = "FathersGivenName"
        case fathersFamilyName = "FathersFamilyName"
    }

    let name: ExtractionFieldDataResponse?
    let surname: ExtractionFieldDataResponse?
    let birthDate: ExtractionFieldDataResponse?
    let gender: ExtractionFieldDataResponse?
    let placeOfBirth: ExtractionFieldDataResponse?
    let nationality: ExtractionFieldDataResponse?
    let documentNumber: ExtractionFieldDataResponse?
    let issuedDate: ExtractionFieldDataResponse?
    let expiryDate: ExtractionFieldDataResponse?
    let countryOfIssue: ExtractionFieldDataResponse?
    let issuingAuthority: ExtractionFieldDataResponse?
    let addressCountry: ExtractionFieldDataResponse?
    let addressZip: ExtractionFieldDataResponse?
    let addressCity: ExtractionFieldDataResponse?
    let addressCounty: ExtractionFieldDataResponse?
    let addressStreet: ExtractionFieldDataResponse?
    let personalIdentificationNumber: ExtractionFieldDataResponse?
    let givenName: ExtractionFieldDataResponse?
    let familyName: ExtractionFieldDataResponse?
    let mothersGivenName: ExtractionFieldDataResponse?
    let mothersFamilyName: ExtractionFieldDataResponse?
    let secondLastName: ExtractionFieldDataResponse?
    let address: ExtractionFieldDataResponse?
    let placeOfIssue: ExtractionFieldDataResponse?
    let fathersGivenName: ExtractionFieldDataResponse?
    let fathersFamilyName: ExtractionFieldDataResponse?
}

struct ExtractionFieldDataResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case read = "Read"
        case validated = "Validated"
        case recommendedValue = "RecommendedValue"
        case mrz = "MRZ"
        case ocr = "OCR"
    }

    let read: Bool?
    let validated: Bool?
    let recommendedValue: String?
    let mrz: ExtractionFieldDataMethodResponse?
    let ocr: ExtractionFieldDataMethodResponse?
}

struct ExtractionFieldDataMethodResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case read = "Read"
        case value = "Value"
        case validated = "Validated"
    }

    let read: Bool?
    let validated: Bool?
    let value: String?
}

struct ExtractionImageDataResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case documents = "Documents"
        case faceImage = "FaceImage"
        case signature = "Signature"
    }

    let documents: [String]?
    let faceImage: String?
    let signature: String?
}
