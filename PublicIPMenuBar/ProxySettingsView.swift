import Combine
import SwiftUI

struct ProxySettingsView: View {
  @State private var service = "Wi-Fi"
  @State private var proxyType = "HTTP"
  @State private var server = ""
  @State private var port = ""
  @State private var requiresAuthentication = false
  @State private var username = ""
  @State private var password = ""
  @State private var output = ""
  @State private var showingConfirmation = false
  @State private var pendingCommand = ""
  @State private var isResetting = false

  let proxyTypes = ["HTTP", "HTTPS", "SOCKS5"]
  let networkServices = ["Wi-Fi", "Ethernet", "USB Ethernet", "Thunderbolt Bridge"]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Group {
        HStack {
          Text("Network Service:")
            .frame(width: 120, alignment: .leading)
          Picker("", selection: $service) {
            ForEach(networkServices, id: \.self) { service in
              Text(service)
            }
          }
          .frame(width: 150)
        }

        HStack {
          Text("Connection Type:")
            .frame(width: 120, alignment: .leading)
          Picker("", selection: $proxyType) {
            ForEach(proxyTypes, id: \.self) { type in
              Text(type)
            }
          }
          .frame(width: 150)
        }

        HStack {
          Text("Proxy URL:")
            .frame(width: 120, alignment: .leading)
          TextField("", text: $server)
        }

        HStack {
          Text("Port:")
            .frame(width: 120, alignment: .leading)
          TextField("", text: $port)
            .frame(width: 100)
            .onReceive(Just(port)) { newValue in
              let filtered = newValue.filter { "0123456789".contains($0) }
              if filtered != newValue {
                self.port = filtered
              }
              if let portNumber = Int(filtered), portNumber > 65535 {
                self.port = String(65535)
              }
            }
          Stepper(
            "",
            value: Binding(
              get: { Int(port) ?? 0 },
              set: { self.port = String($0) }
            ), in: 0...65535)
        }

        Toggle("Proxy server requires password", isOn: $requiresAuthentication)

        if requiresAuthentication {
          HStack {
            Text("Username:")
              .frame(width: 120, alignment: .leading)
            TextField("", text: $username)
          }
          HStack {
            Text("Password:")
              .frame(width: 120, alignment: .leading)
            SecureField("", text: $password)
          }
        }
      }
      .padding(.horizontal)

      Spacer()

      HStack {
        Spacer()
        Button("Apply") {
          prepareToApplySettings()
        }
        Button("Reset") {
          prepareToResetSettings()
        }
        Spacer()
      }
      .padding(.bottom)

      Text(output)
        .foregroundColor(.red)
        .padding()
    }
    .frame(width: 350, height: 300)
    .padding()
    .alert("Confirm Settings Change", isPresented: $showingConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Proceed") {
        executeCommand(pendingCommand)
      }
    } message: {
      Text(confirmationMessage())
    }
  }

  func prepareToApplySettings() {
    guard !server.isEmpty, !port.isEmpty else {
      output = "Server and port are required."
      return
    }

    let proxyTypeCommand: String
    switch proxyType {
    case "HTTP":
      proxyTypeCommand = "web"
    case "HTTPS":
      proxyTypeCommand = "secureweb"
    case "SOCKS5":
      proxyTypeCommand = "socksfirewall"
    default:
      output = "Invalid proxy type selected."
      return
    }

    var command = "networksetup -set\(proxyTypeCommand)proxy '\(service)' \(server) \(port)"

    if requiresAuthentication {
      if !username.isEmpty, !password.isEmpty {
        command += " on '\(username)' '\(password)'"
      } else {
        output = "Username and password are required for authentication."
        return
      }
    } else {
      command += " on"
    }

    pendingCommand = command
    isResetting = false
    showingConfirmation = true
  }

  func prepareToResetSettings() {
    let proxyTypeCommand: String
    switch proxyType {
    case "HTTP":
      proxyTypeCommand = "web"
    case "HTTPS":
      proxyTypeCommand = "secureweb"
    case "SOCKS5":
      proxyTypeCommand = "socksfirewall"
    default:
      output = "Invalid proxy type selected."
      return
    }

    pendingCommand = "networksetup -set\(proxyTypeCommand)proxystate '\(service)' off"
    isResetting = true
    showingConfirmation = true
  }

  func confirmationMessage() -> String {
    if isResetting {
      return
        "This action will reset the proxy settings for \(service) (\(proxyType)). Do you want to proceed?"
    } else {
      return """
        This action will alter your system settings.
        Network Service: \(service)
        Proxy Type: \(proxyType)
        Proxy URL: \(server)
        Port: \(port)
        \(requiresAuthentication ? "Username: \(username)" : "")
        Do you want to proceed?
        """
    }
  }

  func executeCommand(_ command: String) {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = [
      "osascript", "-e", "do shell script \"\(command)\" with administrator privileges",
    ]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    do {
      try task.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let result = String(data: data, encoding: .utf8) {
        output = "Command executed successfully. Result: \(result)"
      } else {
        output = "Command executed successfully, but no output was returned."
      }
    } catch {
      output = "Failed to execute command. Error: \(error.localizedDescription)"
    }
  }
}

