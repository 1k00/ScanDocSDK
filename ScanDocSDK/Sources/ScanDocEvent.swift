import UIKit

public enum ScanDocEvent {

    case validationInProgress(infoCode: String)
    case extractionInProgress
    case extracted(documentImages: [UIImage]?,
                   faceImage: UIImage?,
                   signatureImage: UIImage?,
                   fields: [ExtractedFieldType: String?])
    case networkError(ScanDocEventError)
}

public enum ScanDocEventError: String, Error {
    
    case badServerResponse
    case unableToAuthenticate
    case cannotParseResponse
    case badUrl
}

public enum ExtractedFieldType: String {

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
