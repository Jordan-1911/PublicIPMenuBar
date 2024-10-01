//
//  AppDelegate.swift
//  PublicIPMenuBar
//
//  Created by jw on 9/30/24.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var proxySettingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startUpdatingIP()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Loading..."

        // Create the menu
        let menu = NSMenu()

        // Add menu items
        menu.addItem(NSMenuItem(title: "Configure Proxy Settings", action: #selector(showProxySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func startUpdatingIP() {
        fetchIP()
        timer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { _ in
            self.fetchIP()
        }
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
                        self.statusItem.button?.title = ip
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

    @objc func showProxySettings() {
        if proxySettingsWindowController == nil {
            let proxySettingsView = ProxySettingsView()

            let hostingController = NSHostingController(rootView: proxySettingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Proxy Settings"
            window.styleMask.remove(.resizable)
            proxySettingsWindowController = NSWindowController(window: window)
        }
        proxySettingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        resetProxySettings()
        NSApplication.shared.terminate(self)
    }

    func resetProxySettings() {
        let networkService = "Wi-Fi" // Adjust as needed
        let proxyTypes = ["web", "secureweb", "socksfirewall"]
        for proxyType in proxyTypes {
            let command = "networksetup -set\(proxyType)proxystate '\(networkService)' off"
            runCommandWithPrivileges(command)
        }
    }

    func runCommandWithPrivileges(_ command: String) {
        let appleScript = """
        do shell script "\(command)" with administrator privileges
        """
        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScript) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}
