## Usage

Integrate ScanDocSDK in just couple of steps:

1. Initialize using **user key** and accepting terms and conditions inside AppDelegate.
```swift
import UIKit
import ScanDocSDK
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ScanDocAPI.initialize(userKey: **user key**,
                              acceptTermsAndConditions: true)

        return true
    }

    func application(_ application: UIApplication,
                     		didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }
}
```
1. Add **ScanDocCameraView** view to capture frames and forward them to SDK for processing.
```swift
import SwiftUI
import ScanDocSDK
struct ContentView: View {

    var body: some View {
        VStack {
            ScanDocCameraView()
        }
    }
}
```

1. Retrieve SDK output events by subscribing to **outputEvent**  publisher.
```swift
import SwiftUI
import ScanDocSDK
struct ContentView: View {

    @State private var eventText: String?
    @State private var documentImages: [UIImage]?
    @State private var faceImage: UIImage?
    @State private var signatureImage: UIImage?
    @State private var fields: [String]?

    var body: some View {
        VStack {
            ScanDocCameraView()
            }
        }
        .onReceive(ScanDocAPI.outputEvent) { event in
            switch event {
            case .validationInProgress(infoCode: let infoCode):
                eventText = "🔎 Validation in progress \"\(infoCode)\""
            case .networkError(let error):
                eventText = "❗ Network error          \"\(error)\"   "
            case .extractionInProgress:
                eventText = "🔬 Extraction in progress!                 "
            case .extracted(let documentImages,
                            let faceImage,
                            let signatureImage,
                            let fields):
                eventText = "✅ Extracted!                              "
                self.documentImages = documentImages
                self.faceImage = faceImage
                self.signatureImage = signatureImage
                var fieldTexts = [String]()
                fields.forEach({ (key, value) in
                    guard let value else { return }
                    fieldTexts.append("\(key.rawValue): \(value)")
                })
                self.fields = fieldTexts
            }
        }
    }
}
```
