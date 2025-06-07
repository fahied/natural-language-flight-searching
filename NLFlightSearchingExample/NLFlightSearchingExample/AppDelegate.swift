//
//  AppDelegate.swift
//  NLFlightSearchingExample
//
//  Created by Александр Пономарев on 04.07.2018.
//  Copyright © 2018 Base team. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

}

