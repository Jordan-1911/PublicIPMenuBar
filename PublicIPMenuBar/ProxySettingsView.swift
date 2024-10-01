import SwiftUI
import Combine

struct ProxySettingsView: View {
    @State private var service = "Wi-Fi"
    @State private var proxyType = "HTTP"
    @State private var server = ""
    @State private var port = ""
    @State private var requiresAuthentication = false
    @State private var username = ""
    @State private var password = ""
    @State private var output = ""

    let proxyTypes = ["HTTP", "HTTPS", "SOCKS5"]
    let networkServices = ["Wi-Fi", "Ethernet", "USB Ethernet", "Thunderbolt Bridge"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Form {
                HStack {
                    Text("Network Service:")
                    Picker("", selection: $service) {
                        ForEach(networkServices, id: \.self) { service in
                            Text(service)
                        }
                    }
                    .frame(width: 150)
                }
                
                HStack {
                    Text("Connection Type:")
                    Picker("", selection: $proxyType) {
                        ForEach(proxyTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .frame(width: 100)
                }
                
                TextField("Proxy URL:", text: $server)
                
                HStack {
                    TextField("Port:", text: $port)
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
                    Stepper("", value: Binding(
                        get: { Int(port) ?? 0 },
                        set: { self.port = String($0) }
                    ), in: 0...65535)
                }
                
                Toggle("Proxy server requires password", isOn: $requiresAuthentication)
                
                if requiresAuthentication {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
                
                HStack {
                    Button("Apply") {
                        applyProxySettings()
                    }
                    Button("Reset") {
                        resetProxySettings()
                    }
                }
            }
            .padding()
            
            Text(output)
                .foregroundColor(.red)
                .padding()
        }
        .frame(width: 350)
    }

    func applyProxySettings() {
        // Validate required inputs
        guard !server.isEmpty, !port.isEmpty else {
            output = "Server and port are required."
            return
        }

        // Map the selected proxy type to the corresponding networksetup command
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

        // Construct the command
        var command = "networksetup -set\(proxyTypeCommand)proxy '\(service)' \(server) \(port)"

        // Handle authentication if required
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

        // Execute the command with administrator privileges
        if runCommandWithPrivileges(command) != nil {
            output = "Proxy settings applied."
        } else {
            output = "Failed to apply proxy settings."
        }
    }

    func resetProxySettings() {
        // Map the selected proxy type to the corresponding networksetup command
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

        // Construct the command to turn off the proxy
        let command = "networksetup -set\(proxyTypeCommand)proxystate '\(service)' off"

        // Execute the command with administrator privileges
        if runCommandWithPrivileges(command) != nil {
            output = "Proxy settings reset."
        } else {
            output = "Failed to reset proxy settings."
        }
    }

    func runCommandWithPrivileges(_ command: String) -> String? {
        // Escape any single quotes in the command to prevent AppleScript errors
        let escapedCommand = command.replacingOccurrences(of: "'", with: "'\\''")
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
