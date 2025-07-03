import SwiftUI
import UIKit
import ScanDocSDK

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ScanDocAPI.initialize(userKey: "<user_key>",
                              acceptTermsAndConditions: true)

        return true
    }

    func application(_ application: UIApplication,
                             didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }
}

@main
struct scandoc_testApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
