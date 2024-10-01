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
    var lastAPICallTime: Date?

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
        menu.addItem(NSMenuItem(title: "Last API Call: Never", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Configure Proxy Settings", action: #selector(showProxySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu

        // Start a timer to update the "Last API Call" menu item
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateLastAPICallMenuItem()
        }
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
                   let ip = json["ip"] as? String
                {
                    DispatchQueue.main.async {
                        self.statusItem.button?.title = ip
                        self.lastAPICallTime = Date()
                        self.updateLastAPICallMenuItem()
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

    func updateLastAPICallMenuItem() {
        guard let menu = statusItem.menu,
              let lastCallItem = menu.item(at: 0) else { return }

        if let lastCallTime = lastAPICallTime {
            let timeSinceLastCall = formatTimeDifference(from: lastCallTime)
            lastCallItem.title = "Last API Call: \(timeSinceLastCall) ago"
        } else {
            lastCallItem.title = "Last API Call: Never"
        }
    }

    func formatTimeDifference(from date: Date) -> String {
        let difference = Int(Date().timeIntervalSince(date))
        
        if difference < 60 {
            return "\(difference) second\(difference == 1 ? "" : "s")"
        } else if difference < 3600 {
            let minutes = difference / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = difference / 3600
            let minutes = (difference % 3600) / 60
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
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
    let networkService = "Wi-Fi"
    let proxyTypes = ["web", "secureweb", "socksfirewall"]
    for proxyType in proxyTypes {
      let command = "networksetup -set\(proxyType)proxystate '\(networkService)' off"
      if let result = runCommandWithPrivileges(command) {
        print("Reset result for \(proxyType) proxy: \(result)")
      } else {
        print("Failed to reset \(proxyType) proxy")
      }
    }
  }

  func runCommandWithPrivileges(_ command: String) -> String? {
    // Escape double quotes and backslashes in the command
    let escapedCommand = command.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")

    let appleScript = """
      do shell script "\(escapedCommand)" with administrator privileges
      """

    var error: NSDictionary?
    if let script = NSAppleScript(source: appleScript) {
      let result = script.executeAndReturnError(&error)
      if let error = error {
        print("AppleScript Error: \(error)")
        return error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error."
      }
      return result.stringValue ?? "Command executed."
    }
    return nil
  }
}
