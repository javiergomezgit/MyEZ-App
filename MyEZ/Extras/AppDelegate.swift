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
                
        setColorBars()

        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM
            Messaging.messaging().delegate = self
            //Messaging.messaging().remoteMeMy InflatablesssageDelegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()

        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
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

        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self // if you handle notifications in-app

        
        IQKeyboardManager.shared.isEnabled = true
        
        return true
    }
    

//    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
//        print(remoteMessage.appData)
//    }
    
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        
//        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
//        
//        return handled
//    }
    
    
    func setColorBars() {
//        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().barTintColor = UIColor(red: 28/255, green: 34/255, blue: 39/255, alpha: 1)
//        //UITabBar.appearance().tintColor = UIAppColors.light
//
//        UINavigationBar.appearance().barTintColor = UIColor(red: 28/255, green: 34/255, blue: 39/255, alpha: 1)
//        //UINavigationBar.appearance().isOpaque = true
//        UINavigationBar.appearance().tintColor = UIAppColors.light
//        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIAppColors.light]
//
//        UIApplication.shared.statusBarStyle = .lightContent
        
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().layer.borderWidth = 0.5
        UITabBar.appearance().clipsToBounds = true
        
//        self.tabBarController!.tabBar.layer.borderWidth = 0.50
//        self.tabBarController!.tabBar.layer.borderColor = UIColor.clearColor().CGColor
//        self.tabBarController?.tabBar.clipsToBounds = true
    }
    
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let pay = notification as? [String: Any]  {
            print (pay)
            if let identifier = pay["identifier"] as? String {
                //do something with the identifier
                //let storyboard = UIStoryboard(name: "Main", bundle: nil)
                //let vc = storyboard.instantiateViewController(withIdentifier: "main")//identifier)
                //window?.rootViewController = vc
                print (identifier)
            }
        }
        
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }
    }
  
    //OLD CODE
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//
//        InstanceID.instanceID().instanceID { (result, error) in
//            if let error = error {
//                print("Error fetching remote instance ID: \(error)")
//            } else if let result = result {
//                print("Remote instance ID token: \(result.token)")
//            }
//        }
//        
//        Messaging.messaging().apnsToken = deviceToken
//        
//        let firebaseAuth = Auth.auth()
//        
//        firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
//        
//    }
    
    //NEW CODE
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        // 1) Give APNs token to FCM (required for push)
        Messaging.messaging().apnsToken = deviceToken

        // 2) Only needed if you use Firebase Auth with APNs (ex: Phone Auth / silent push auth flows)
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif


        // 3) (Optional) Force-fetch current FCM token right after APNs token set
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            print("FCM token (manual fetch): \(token ?? "nil")")
        }
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

    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
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
                TabBarButton(
                    systemImage: "storefront",
                    tab: .browse,
                    selectedTab: $selectedTab
                )

                TabBarButton(
                    systemImage: "tag",
                    tab: .deals,
                    selectedTab: $selectedTab
                )

                MyEZTabButton(selectedTab: $selectedTab)

                TabBarButton(
                    systemImage: "ellipsis.message",
                    tab: .contact,
                    selectedTab: $selectedTab
                )

                TabBarButton(
                    systemImage: "person",
                    tab: .profile,
                    selectedTab: $selectedTab
                )
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
