//
//  PublicIPMenuBarAppApp.swift
//  PublicIPMenuBarApp
//
//  Created by jw on 9/30/24.
//

import SwiftUI

@main
struct PublicIPMenuBarAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Loading..."

        fetchIP()

        // Schedule the timer to update every 3 minutes (180 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { _ in
            self.fetchIP()
        }

        constructMenu()
    }

    func fetchIP() {
        let url = URL(string: "https://api64.ipify.org?format=json")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.statusItem.button?.title = "Error"
                }
                print("Error fetching IP: \(error)")
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.statusItem.button?.title = "No Data"
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let ip = json["ip"] as? String {
                    DispatchQueue.main.async {
                        self.statusItem.button?.title = "IP: \(ip)"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusItem.button?.title = "Parse Error"
                }
                print("Error parsing JSON: \(error)")
            }
        }
        task.resume()
    }

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func quit() {
        NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}


