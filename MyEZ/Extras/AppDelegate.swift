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
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.surfacePrimary)
        appearance.shadowColor = UIColor(AppColors.borderSubtle)

        let normalColor = UIColor(AppColors.textMuted)
        let selectedColor = UIColor(AppColors.buttonBlueEnd)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = normalColor
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
                .background(AppColors.backgroundBottom.ignoresSafeArea())

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
            NavigationStack {
                MyEZView()
            }
            .padding(.horizontal, 20)
        case .contact:
            NavigationStack {
                ContactView()
            }
            .padding(.horizontal, 20)
        case .profile:
            NavigationStack {
                ProfileView(appState: appState)
            }
            .padding(.horizontal, 20)
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
    private let barHeight: CGFloat = 75

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.97))
                .frame(height: barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)

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
        .padding(.bottom, -10)
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
                        .fill(
                            LinearGradient(
                                colors: [AppColors.sceneBlueGlow.opacity(0.95), AppColors.secondary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 54, height: 40)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? .white : AppColors.textMuted)
            }
            .frame(width: 58, height: 50)
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
                        .fill(AppColors.accentRed)
                        .frame(width: baseSize, height: baseSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(AppColors.borderSubtle, lineWidth: 1)
                        )
                        .frame(width: baseSize, height: baseSize)
                }
                Image("logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 29, height: 29)
                    .foregroundColor(isSelected ? .white : AppColors.buttonBlueEnd)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("MyEZ")
    }
}
