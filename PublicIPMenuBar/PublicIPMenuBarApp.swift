//
//  PublicIPMenuBarApp.swift
//  PublicIPMenuBar
//
//  Created by jw on 9/30/24.
//

import SwiftUI

@main
struct PublicIPMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
