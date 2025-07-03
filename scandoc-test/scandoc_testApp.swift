//
//  scandoc_testApp.swift
//  scandoc-test
//
//  Created by Zvone on 6/12/25.
//
import SwiftUI
import UIKit
import ScanDocSDK

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ScanDocAPI.initialize(userKey: "bcca7036-0ac2-4f35-96c0-47a8bf685642ef851781-f199-408b-885a-49d338858ef58b327401-acd7-485b-956e-e3e57651093891ce09d8-8f2f-473f-92ca-0aca4ac8116c2cf7f724-8c87-490c-9531-3ca5d1861ba291aa13bf-7f5a-4f54-9527-90e7279748ca522cb6fc-180c-48ae-afcf-c6927033a742ecbbacf2-165b-41b2-bc0f-05c5a929eea2b5c4961c-4f28-4178-b4c7-7efdbc54818659ae2ea3-f609-4e62-b569-799e161da9c1",
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
