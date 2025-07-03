//
//  ContentView.swift
//  scandoc-test
//
//  Created by Zvone on 6/12/25.
//

import SwiftUI
import ScanDocSDK
import CoreNFC
import NFCPassportReader

struct PassportDetailView: View {
    let passport: NFCPassportModel

    var body: some View {
        VStack(spacing: 16) {
            if let faceImage = passport.passportImage {
                Image(uiImage: faceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            Text("Passport read successfully!")
                .font(.headline)
            Text("Name: \(passport.firstName) \(passport.lastName)")
            Text("Document Number: \(passport.documentNumber)")
        }
        .padding()
    }
}

struct PassportScannerView: View {
    @State private var isLoading = true
    @State private var result: NFCPassportModel?
    @State private var error: Error?
    @State private var passport: NFCPassportModel?
    let onStartOver: () -> Void
    let mrzKey: String

    private func startScan() {
        isLoading = true
        result = nil
        error = nil

        Task {
            let customMessageHandler: (NFCViewDisplayMessage) -> String? = { displayMessage in
                switch displayMessage {
                case .requestPresentPassport:
                    return "Hold your iPhone near an NFC enabled passport."
                default:
                    return nil
                }
            }

            do {
                let passportReader = PassportReader()
                let passport = try await passportReader.readPassport(
                    mrzKey: mrzKey,
                    skipCA: true,
                    skipPACE: true,
                    useExtendedMode: true,
                    customDisplayMessage: customMessageHandler
                )

                if let _ = passport.faceImageInfo {
                    print("Got face Image details")
                }

                DispatchQueue.main.async {
                    self.passport = passport
                    self.isLoading = false // <-- Add this line
                    print("Passport read successfully! \(passport)")
                }
            } catch {
                DispatchQueue.main.async {
                    if let nfcError = error as? NFCReaderError {
                        switch nfcError.code {
                        case .readerSessionInvalidationErrorUserCanceled:
                            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC session was canceled. Please try again."])
                        case .readerSessionInvalidationErrorSessionTimeout:
                            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC session timed out. Please try again."])
                        default:
                            self.error = error
                        }
                    } else {
                        self.error = error
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func retryScan() {
        isLoading = true
        result = nil
        error = nil
        // Add a short delay before starting a new scan
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            startScan()
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Scanning passport...")
                    .onAppear {
                        startScan()
                    }
            } else if let passport = passport {
                PassportDetailView(passport: passport)
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                Button("Retry NFC Scan") {
                    retryScan()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                Button("Go back") {
                    onStartOver()
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct ContentView: View {
    
    @State private var eventText: String?
    @State private var documentImages: [UIImage]?
    @State private var faceImage: UIImage?
    @State private var signatureImage: UIImage?
    @State private var fields: [String]?
    @State private var showPassportScanner = false
    @State private var mrzKey: String?
    @State private var showCameraView = true
    
    
    private func handleTryAgain() {
        eventText = nil
        documentImages = nil
        faceImage = nil
        signatureImage = nil
        fields = nil
        self.showCameraView = true
    }
    
    private func handleContinueWithNFC() {
        showPassportScanner = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if self.showCameraView {
                ScanDocCameraView()
                    .edgesIgnoringSafeArea(.all)
            }
            VStack(alignment: .leading, spacing: 8) {
                if let eventText = eventText, fields == nil {
                    Text(eventText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 8)
                }
                if let fields = fields {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Extracted Fields:")
                            .font(.headline)
                            .foregroundColor(.white)
                        ForEach(fields, id: \.self) { field in
                            Text(field)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        Button(action: handleTryAgain) {
                            Text("Try again!")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                        Button(action: handleContinueWithNFC) {
                            Text("Continue with NFC")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
                }
            }
            .onReceive(ScanDocAPI.outputEvent) { event in
                switch event {
                case .validationInProgress(infoCode: let infoCode):
                    print("🔎 Validation in progress \"\(infoCode)\"")
                    eventText = "🔎 Validation in progress \"\(infoCode)\""
                case .networkError(let error):
                    eventText = "❗ Network error          \"\(error)\"   "
                case .extractionInProgress:
                    eventText = "🔬 Extraction in progress!                 "
                case .extracted(let documentImages,
                                let faceImage,
                                let signatureImage,
                                let fields):
                    print("Extracted! Document images!")
                    eventText = "✅ Extracted!                              "
                    self.documentImages = documentImages
                    self.faceImage = faceImage
                    self.signatureImage = signatureImage
                    var fieldTexts = [String]()
                    fields.forEach({ (key, value) in
                        guard let value else { return }
                        print("Field: \(key.rawValue): \(value)")
                        fieldTexts.append("\(key.rawValue): \(value)")
                    })
                    self.fields = fieldTexts
                    
                    self.showCameraView = false
                    
                    if let documentNumber = fields.first(where: { $0.key == .documentNumber })?.value,
                       let dateOfBirth = fields.first(where: { $0.key == .birthDate })?.value,
                       let expiryDate = fields.first(where: { $0.key == .expiryDate })?.value {
                        let passportUtils = PassportUtils()
                        self.mrzKey = passportUtils.getMRZKey(passportNumber: documentNumber, dateOfBirth: dateOfBirth, dateOfExpiry: expiryDate)
                        
                        print("MRZ Key: \(self.mrzKey ?? "N/A")")
                        print("Document Number: \(documentNumber)")
                        print("Date of Birth: \(dateOfBirth)")
                        print("Expiry Date: \(expiryDate)")
                    }
                }
            }
        }
        .sheet(isPresented: $showPassportScanner) {
            if let mrzKey = self.mrzKey {
                    PassportScannerView(onStartOver: {
                        self.showPassportScanner = false
                        self.handleTryAgain()
                    }, mrzKey: mrzKey)
                } else {
                    Text("MRZ key not available")
                }
        }
    }
}
