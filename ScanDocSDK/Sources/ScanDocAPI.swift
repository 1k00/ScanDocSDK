import UIKit
import Combine

public final class ScanDocAPI {

    private let keyServiceBaseUrl = "https://api.scandoc.ai/ks/"
    private let scanAppBaseUrl = "https://api.scandoc.ai/ss/"
    private let outputEventSubject = PassthroughSubject<ScanDocEvent, Never>()
    private lazy var cameraImageStreamSubject = PassthroughSubject<UIImage, Never>()
    private lazy var serialDispatchQueue = DispatchQueue(label: String(describing: ScanDocAPI.self),
                                                         qos: .userInitiated)
    private lazy var userDefaultsService = UserDefaultsService()
    private lazy var jsonDecoder = JSONDecoder()
    private lazy var jsonEncoder = JSONEncoder()
    private lazy var outputEventPublisher: AnyPublisher<ScanDocEvent, Never> = {
        initializeNetworkingAndOutputEvents()

        return outputEventSubject
            .subscribe(on: serialDispatchQueue)
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
    }()
    @Atomic private var userKey: String = ""
    @Atomic private var subClient: String = ""
    @Atomic private var accessToken: String = ""
    @Atomic private var refreshToken: String = ""
    @Atomic private var acceptTermsAndConditions: Bool = false
    private var cancellable: AnyCancellable?
    static let shared = ScanDocAPI()

    private init() { }
}

// Public
public extension ScanDocAPI {

    static func initialize(userKey: String, 
                           acceptTermsAndConditions: Bool) {
        shared
            .initialize(userKey: userKey,
                        acceptTermsAndConditions: acceptTermsAndConditions)
    }

    static var outputEvent: AnyPublisher<ScanDocEvent, Never> {
        shared.outputEventPublisher
    }
}

// Internal
extension ScanDocAPI {

    func onImageFromCamera(image: UIImage) {
        cameraImageStreamSubject.send(image)
    }
}

// Initialize
private extension ScanDocAPI {

    func initialize(userKey: String,
                    acceptTermsAndConditions: Bool) {
        self.acceptTermsAndConditions = acceptTermsAndConditions
        self.userKey = userKey
        if let subClient = userDefaultsService.subClient {
            self.subClient = subClient
        } else {
            let uuidString = UUID().uuidString
            userDefaultsService.subClient = uuidString
            self.subClient = uuidString
        }
    }

    func initializeNetworkingAndOutputEvents() {
        serialDispatchQueue.async { [weak self] in
            guard let self else { return }
            Task {
                while true {
                    let authenticateResult = await self.authenticate(keyServiceBaseUrl: self.keyServiceBaseUrl,
                                                                     userKey: self.userKey,
                                                                     subClient: self.subClient,
                                                                     jsonEncoder: self.jsonEncoder,
                                                                     jsonDecoder: self.jsonDecoder)
                    switch authenticateResult {
                    case .success(let authenticationResponse):
                        self.accessToken = authenticationResponse.accessToken
                        self.refreshToken = authenticationResponse.refreshToken
                        while true {
                            let images = await self.getValidatedImages(
                                keyServiceBaseUrl: self.keyServiceBaseUrl,
                                outputEventSubject: self.outputEventSubject,
                                acceptTermsAndConditions: self.acceptTermsAndConditions,
                                jsonEncoder: self.jsonEncoder,
                                jsonDecoder: self.jsonDecoder)
                            // sleep to give time for threads to send output and pause because potential network errors
                            try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                            let extractionResult = await self.extract(
                                images: images,
                                keyServiceBaseUrl: self.keyServiceBaseUrl,
                                shouldDoAuthenticationIfNeeded: true,
                                outputEventSubject: self.outputEventSubject,
                                acceptTermsAndConditions: self.acceptTermsAndConditions,
                                jsonEncoder: self.jsonEncoder,
                                jsonDecoder: self.jsonDecoder)
                            await self.sendOutputFromExtractionResponse(
                                result: extractionResult,
                                outputEventSubject: self.outputEventSubject)
                        }
                    case .failure(let error):
                        self.outputEventSubject.send(.networkError(error))
                    }
                    try? await Task.sleep(nanoseconds: UInt64(2.0 * Double(NSEC_PER_SEC)))
                }
            }
        }
    }
}

// Extraction
private extension ScanDocAPI {

    func extract(images: [UIImage],
                 keyServiceBaseUrl: String,
                 shouldDoAuthenticationIfNeeded: Bool,
                 outputEventSubject: PassthroughSubject<ScanDocEvent, Never>,
                 acceptTermsAndConditions: Bool,
                 jsonEncoder: JSONEncoder,
                 jsonDecoder: JSONDecoder) async -> Result<ExtractionResponse, ScanDocEventError> {
        outputEventSubject.send(.extractionInProgress)
        guard let url = URL(string: scanAppBaseUrl + "extraction/") else {
            return .failure(.badUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = [
          "content-type": "application/json",
          "accept": "application/json",
          "Authorization": accessToken,
        ]
        if let frontBase64Image = images[safe: 0]?.pngData()?.base64EncodedString() {
            let backImage: String?
            let backImageType: String?
            let backImageCropped: Bool?
            if let backBase64Image = images[safe: 1]?.pngData()?.base64EncodedString() {
                backImage = backBase64Image
                backImageType = "base64"
                backImageCropped = false
            } else {
                backImage = nil
                backImageType = nil
                backImageCropped = nil
            }
            let dataFields = ExtractionDataFieldsRequest(frontImage: frontBase64Image,
                                                         frontImageType: "base64",
                                                         frontImageCropped: false,
                                                         backImage: backImage,
                                                         backImageType: backImageType,
                                                         backImageCropped: backImageCropped)
            let settings = ExtractionSettingsRequest(ignoreBackImage: true,
                                                     shouldReturnDocumentImage: true,
                                                     shouldReturnFaceIfDetected: true,
                                                     shouldReturnSignatureIfDetected: true,
                                                     skipDocumentsSizeCheck: true,
                                                     skipImageSizeCheck: true,
                                                     canStoreImages: false,
                                                     enforceDocsSameCountryTypeSeries: false,
                                                     caseSensitiveOutput: true,
                                                     faceImageResize: nil,
                                                     signatureImageResize: nil,
                                                     segmentedImageResize: nil,
                                                     storeFaceImage: false,
                                                     dontUseValidation: true)
            let extractionRequest = ExtractionRequest(acceptTermsAndConditions: acceptTermsAndConditions,
                                                      dataFields: dataFields,
                                                      settings: settings)
            request.httpBody = try? jsonEncoder.encode(extractionRequest)
        }
        let dataResponse = try? await URLSession
            .shared
            .data(for: request)
        guard let (data, response) = dataResponse else {
            return .failure(.badServerResponse)
        }
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            return .failure(.badServerResponse)
        }
        guard httpUrlResponse.statusCode == 200 else {
            if httpUrlResponse.statusCode == 401 {
                if shouldDoAuthenticationIfNeeded {
                    let authenticationRefresh = try? await authenticateRefresh(
                        keyServiceBaseUrl: keyServiceBaseUrl,
                        jsonEncoder: jsonEncoder,
                        jsonDecoder: jsonDecoder)
                        .get()
                    if let accessToken = authenticationRefresh?.accessToken {
                        self.accessToken = accessToken
                        return await extract(images: images,
                                             keyServiceBaseUrl: keyServiceBaseUrl,
                                             shouldDoAuthenticationIfNeeded: false,
                                             outputEventSubject: outputEventSubject,
                                             acceptTermsAndConditions: acceptTermsAndConditions,
                                             jsonEncoder: jsonEncoder,
                                             jsonDecoder: jsonDecoder)
                    } else {
                        return .failure(.unableToAuthenticate)
                    }
                } else {
                    return .failure(.unableToAuthenticate)
                }
            } else {
                return .failure(.badServerResponse)
            }
        }
        guard let extractionResponse = try? jsonDecoder
            .decode(ExtractionResponse.self, from: data) else {
            return .failure(.cannotParseResponse)
        }

        return .success(extractionResponse)
    }

    func sendOutputFromExtractionResponse(
        result: Result<ExtractionResponse, ScanDocEventError>,
        outputEventSubject: PassthroughSubject<ScanDocEvent, Never>) async {
            let event: ScanDocEvent
            switch result {
            case .success(let extractionRespone):
                let documentImages = extractionRespone
                    .imageData?
                    .documents?
                    .compactMap({ stringData -> UIImage? in
                        guard let data = Data(base64Encoded: stringData) else {
                            return nil
                        }
                        
                        return UIImage(data: data)
                    })
                let faceImage: UIImage?
                if let faceImageString = extractionRespone
                    .imageData?
                    .faceImage,
                   let faceImageData = Data(base64Encoded: faceImageString) {
                    faceImage = UIImage(data: faceImageData)
                } else {
                    faceImage = nil
                }
                let signatureImage: UIImage?
                if let signatureImageString = extractionRespone
                    .imageData?
                    .signature,
                   let signatureImageData = Data(base64Encoded: signatureImageString) {
                    signatureImage = UIImage(data: signatureImageData)
                } else {
                    signatureImage = nil
                }
                let fields: [ExtractedFieldType: String?] =
                [.name: getValueFromFieldData(fieldData: extractionRespone.data?.name),
                 .surname: getValueFromFieldData(fieldData: extractionRespone.data?.surname),
                 .birthDate: getValueFromFieldData(fieldData: extractionRespone.data?.birthDate),
                 .gender: getValueFromFieldData(fieldData: extractionRespone.data?.gender),
                 .placeOfBirth: getValueFromFieldData(fieldData: extractionRespone.data?.placeOfBirth),
                 .nationality: getValueFromFieldData(fieldData: extractionRespone.data?.nationality),
                 .documentNumber: getValueFromFieldData(fieldData: extractionRespone.data?.documentNumber),
                 .issuedDate: getValueFromFieldData(fieldData: extractionRespone.data?.issuedDate),
                 .expiryDate: getValueFromFieldData(fieldData: extractionRespone.data?.expiryDate),
                 .countryOfIssue: getValueFromFieldData(fieldData: extractionRespone.data?.countryOfIssue),
                 .issuingAuthority: getValueFromFieldData(fieldData: extractionRespone.data?.issuingAuthority),
                 .addressCountry: getValueFromFieldData(fieldData: extractionRespone.data?.addressCountry),
                 .addressZip: getValueFromFieldData(fieldData: extractionRespone.data?.addressZip),
                 .addressCity: getValueFromFieldData(fieldData: extractionRespone.data?.addressCity),
                 .addressCounty: getValueFromFieldData(fieldData: extractionRespone.data?.addressCounty),
                 .addressStreet: getValueFromFieldData(fieldData: extractionRespone.data?.addressStreet),
                 .personalIdentificationNumber: getValueFromFieldData(fieldData: extractionRespone.data?.personalIdentificationNumber),
                 .givenName: getValueFromFieldData(fieldData: extractionRespone.data?.givenName),
                 .familyName: getValueFromFieldData(fieldData: extractionRespone.data?.familyName),
                 .mothersGivenName: getValueFromFieldData(fieldData: extractionRespone.data?.mothersGivenName),
                 .mothersFamilyName: getValueFromFieldData(fieldData: extractionRespone.data?.mothersFamilyName),
                 .secondLastName: getValueFromFieldData(fieldData: extractionRespone.data?.secondLastName),
                 .address: getValueFromFieldData(fieldData: extractionRespone.data?.address),
                 .placeOfIssue: getValueFromFieldData(fieldData: extractionRespone.data?.placeOfIssue),
                 .fathersGivenName: getValueFromFieldData(fieldData: extractionRespone.data?.fathersGivenName),
                 .fathersFamilyName: getValueFromFieldData(fieldData: extractionRespone.data?.fathersFamilyName)]
                
                event = .extracted(documentImages: documentImages,
                                   faceImage: faceImage,
                                   signatureImage: signatureImage,
                                   fields: fields)
            case .failure(let error):
                event = .networkError(error)
            }
            outputEventSubject.send(event)
        }
    
    func getValueFromFieldData(fieldData: ExtractionFieldDataResponse?) -> String? {
        guard let fieldData else {
            return nil
        }
        
        return fieldData.read ?? false ? fieldData.recommendedValue : nil
    }
}

// Validation
private extension ScanDocAPI {
    
    func getValidatedImages(keyServiceBaseUrl: String,
                            outputEventSubject: PassthroughSubject<ScanDocEvent, Never>,
                            acceptTermsAndConditions: Bool,
                            jsonEncoder: JSONEncoder,
                            jsonDecoder: JSONDecoder) async -> [UIImage] {
        var blurValues = [Double]()
        var doubleSideDocumentValidations = [ValidationSideResponse: (ValidationResponse, UIImage)]()
        while true {
            let (image, resizedImage) = await fetchImageFromStream()
            let validationResult = await validate(image: resizedImage,
                                                  keyServiceBaseUrl: keyServiceBaseUrl,
                                                  shouldDoAuthenticationIfNeeded: true,
                                                  blurValues: blurValues,
                                                  acceptTermsAndConditions: acceptTermsAndConditions,
                                                  jsonEncoder: jsonEncoder,
                                                  jsonDecoder: jsonDecoder)
            switch validationResult {
                
            case .success(let validationResponse):
                if let detectedBlurValue = validationResponse.detectedBlurValue {
                    blurValues.append(detectedBlurValue)
                } else {
                    blurValues = []
                }
                outputEventSubject.send(.validationInProgress(infoCode: validationResponse.infoCode))
                if validationResponse.validated ?? false {
                    if validationResponse.infoCode.trimmingCharacters(in: .whitespacesAndNewlines) == "1000" {
                        return [image]
                    } else if validationResponse.infoCode.trimmingCharacters(in: .whitespacesAndNewlines) == "1007" {
                        if let validationSideResponse = validationResponse.side {
                            doubleSideDocumentValidations[validationSideResponse] = (validationResponse, image)
                        }
                        let filteredDocumnetValidations = doubleSideDocumentValidations
                            .filter({ $0.key == .front || $0.key == .back })
                        if filteredDocumnetValidations.contains(where: { $0.key == .front }),
                           filteredDocumnetValidations.contains(where: { $0.key == .back }),
                           let country = filteredDocumnetValidations.first.map({ $0.value.0.country }),
                           filteredDocumnetValidations.allSatisfy({ $0.value.0.country == country }) {
                            let images = filteredDocumnetValidations
                                .map({ $0.value.1 })

                            return images
                        }
                    }
                }
            case .failure(let error):
                outputEventSubject.send(.networkError(error))
                try? await Task.sleep(nanoseconds: UInt64(0.2 * Double(NSEC_PER_SEC)))
            }
        }
    }
    
    func validate(image: UIImage,
                  keyServiceBaseUrl: String,
                  shouldDoAuthenticationIfNeeded: Bool,
                  blurValues: [Double],
                  acceptTermsAndConditions: Bool,
                  jsonEncoder: JSONEncoder,
                  jsonDecoder: JSONDecoder) async -> Result<ValidationResponse, ScanDocEventError> {
        guard let url = URL(string: scanAppBaseUrl + "validation/") else {
            return .failure(.badUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "content-type": "application/json",
          "Authorization": accessToken,
        ]
        let base64Image = image.pngData()?.base64EncodedString()
        let validationRequest = ValidationRequest(
            acceptTermsAndConditions: acceptTermsAndConditions,
            dataFields: ValidationDataFieldsRequest(images: [base64Image].compactMap({ $0 }),
                                                    blurValues: blurValues))
        request.httpBody = try? jsonEncoder.encode(validationRequest)
        let dataResponse = try? await URLSession
            .shared
            .data(for: request)
        guard let (data, response) = dataResponse else {
            return .failure(.badServerResponse)
        }
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            return .failure(.badServerResponse)
        }
        guard httpUrlResponse.statusCode == 200 else {
            if httpUrlResponse.statusCode == 401 {
                if shouldDoAuthenticationIfNeeded {
                    let authenticationRefresh = try? await authenticateRefresh(
                        keyServiceBaseUrl: keyServiceBaseUrl,
                        jsonEncoder: jsonEncoder,
                        jsonDecoder: jsonDecoder)
                        .get()
                    if let accessToken = authenticationRefresh?.accessToken {
                        self.accessToken = accessToken
                        return await validate(image: image,
                                              keyServiceBaseUrl: keyServiceBaseUrl,
                                              shouldDoAuthenticationIfNeeded: false,
                                              blurValues: blurValues,
                                              acceptTermsAndConditions: acceptTermsAndConditions,
                                              jsonEncoder: jsonEncoder,
                                              jsonDecoder: jsonDecoder)
                    } else {
                        return .failure(.unableToAuthenticate)
                    }
                } else {
                    return .failure(.unableToAuthenticate)
                }
            } else {
                return .failure(.badServerResponse)
            }
        }
        guard let validationResponse = try? jsonDecoder
            .decode(ValidationResponse.self, from: data) else {
            return .failure(.cannotParseResponse)
        }

        return .success(validationResponse)
    }

    func fetchImageFromStream() async -> (image: UIImage,
                                          resizedImage: UIImage) {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            self.cancellable = self.cameraImageStreamSubject
                .prefix(1)
                .sink(receiveValue: { image in
                    let heightInPixels = image.size.height * image.scale
                    let widthInPixels = image.size.width * image.scale
                    let resizingCoef = max(heightInPixels, widthInPixels) / 384
                    let newHeight = heightInPixels / resizingCoef
                    let newWidth = widthInPixels / resizingCoef
                    let resizedImage = image
                        .resizeImage(targetSize: CGSize(width: newWidth, height: newHeight))
                    continuation.resume(returning: (image, resizedImage))
                })
        }
    }
}

// Auth
private extension ScanDocAPI {

    func authenticate(keyServiceBaseUrl: String,
                      userKey: String,
                      subClient: String,
                      jsonEncoder: JSONEncoder,
                      jsonDecoder: JSONDecoder) async -> Result<AuthenticateResponse, ScanDocEventError> {
        guard let url = URL(string: keyServiceBaseUrl + "authenticate/") else {
            return .failure(.badUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "content-type": "application/json"
        ]
        let authenticateRequest = AuthenticateRequest(userKey: userKey,
                                                      subClient: subClient)
        request.httpBody = try? jsonEncoder.encode(authenticateRequest)
        let dataResponse = try? await URLSession
            .shared
            .data(for: request)
        guard let (data, response) = dataResponse else {
            return .failure(.badServerResponse)
        }
        if let httpUrlResponse = response as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            return .failure(.badServerResponse)
        }
        guard let authenticateResponse = try? jsonDecoder
            .decode(AuthenticateResponse.self, from: data) else {
            return .failure(.cannotParseResponse)
        }

        return .success(authenticateResponse)
    }

    func authenticateRefresh(keyServiceBaseUrl: String,
                             jsonEncoder: JSONEncoder,
                             jsonDecoder: JSONDecoder)
    async -> Result<AuthenticateRefreshResponse, ScanDocEventError> {
        guard let url = URL(string: keyServiceBaseUrl + "authenticate/refresh") else {
            return .failure(.badUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "content-type": "application/json"
        ]
        let authenticateRefreshRequest = AuthenticateRefreshRequest(refreshToken: refreshToken)
        request.httpBody = try? jsonEncoder.encode(authenticateRefreshRequest)
        let dataResponse = try? await URLSession
            .shared
            .data(for: request)
        guard let (data, response) = dataResponse else {
            return .failure(.badServerResponse)
        }
        if let httpUrlResponse = response as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            return .failure(.badServerResponse)
        }
        guard let authenticateRefreshResponse = try? jsonDecoder
            .decode(AuthenticateRefreshResponse.self, from: data) else {
            return .failure(.cannotParseResponse)
        }

        return .success(authenticateRefreshResponse)
    }
}
