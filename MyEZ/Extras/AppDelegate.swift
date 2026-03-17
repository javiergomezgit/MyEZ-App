//
//  AppDelegate.swift
//  My EZ
//
//  Created by Javier Gomez on 8/9/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import SwiftUI
import Firebase
import FirebaseAuth
//import FirebaseInstanceID
import FirebaseMessaging
import UserNotifications

import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    let appState = AppState()
    var window: UIWindow?
    static var deviceIDToken = String()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase must be configured before delegates or auth
        FirebaseApp.configure()

        // Set delegates once
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Request notification permission — single code path
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
                return
            }
            guard granted else {
                print("Notification permission not granted")
                return
            }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        setColorBars()
        IQKeyboardManager.shared.isEnabled = true

        return true
    }

    func setColorBars() {
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().layer.borderWidth = 0.5
        UITabBar.appearance().clipsToBounds = true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Let Firebase Auth handle silent push notifications first
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        // Handle app-specific notifications
        if let payload = notification as? [String: Any] {
            print("Remote notification payload: \(payload)")
            if let identifier = payload["identifier"] as? String {
                print("Notification identifier: \(identifier)")
            }
        }
        completionHandler(.newData)
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass APNs token to FCM
        Messaging.messaging().apnsToken = deviceToken

        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("Firebase registration token: \(fcmToken)")
        AppDelegate.deviceIDToken = fcmToken
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": fcmToken]
        )
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct MyEZApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView(appState: appDelegate.appState)
        }
    }
}

struct RootTabView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: RootTab = .browse

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.dark.ignoresSafeArea())

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .browse:
            NavigationStack { BrowseView() }
        case .deals:
            NavigationStack { DealsView() }
        case .myez:
            NavigationStack { MyEZView() }
        case .contact:
            NavigationStack { ContactView() }
        case .profile:
            NavigationStack { ProfileView(appState: appState) }
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()
            Text(title)
                .font(.title2)
                .foregroundColor(AppColors.light)
        }
        .navigationTitle(title)
    }
}

enum RootTab: String {
    case browse
    case deals
    case myez
    case contact
    case profile
}

struct CustomTabBar: View {
    @Binding var selectedTab: RootTab
    private let barHeight: CGFloat = 70

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.dark)
                .frame(height: barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.light.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: AppColors.dark.opacity(0.4), radius: 16, x: 0, y: 6)

            HStack(spacing: 22) {
                TabBarButton(systemImage: "storefront", tab: .browse, selectedTab: $selectedTab)
                TabBarButton(systemImage: "tag", tab: .deals, selectedTab: $selectedTab)
                MyEZTabButton(selectedTab: $selectedTab)
                TabBarButton(systemImage: "ellipsis.message", tab: .contact, selectedTab: $selectedTab)
                TabBarButton(systemImage: "person", tab: .profile, selectedTab: $selectedTab)
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

struct TabBarButton: View {
    let systemImage: String
    let tab: RootTab
    @Binding var selectedTab: RootTab
    private var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(AppColors.secondary)
                        .frame(width: 50, height: 30)
                }
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? .white : AppColors.light.opacity(0.45))
            }
            .frame(width: 54, height: 44)
        }
        .buttonStyle(.plain)
    }
}

struct MyEZTabButton: View {
    @Binding var selectedTab: RootTab
    private var isSelected: Bool { selectedTab == .myez }
    private let baseSize: CGFloat = 54

    var body: some View {
        Button {
            selectedTab = .myez
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: baseSize, height: baseSize)
                } else {
                    Circle()
                        .stroke(AppColors.light.opacity(0.45), lineWidth: 2)
                        .frame(width: baseSize, height: baseSize)
                }
                Image("logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? AppColors.light : AppColors.light.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("MyEZ")
    }
}
