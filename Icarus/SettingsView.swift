import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("refreshInterval") private var refreshInterval: Int = 30
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSignedIn = false
    @State private var showSignInSheet = false
    @State private var apiURL: String = ""
    @State private var apiKey: String = ""
    @State private var isURLValid: Bool = true
    @State private var connectionStatus: String? = nil
    @State private var isTesting: Bool = false
    @FocusState private var focusedField: Field?

    enum Field {
        case apiURL, apiKey
    }

    var body: some View {
        NavigationStack {
            Form {
                // ACCOUNT SECTION
                Section(header: Text("Account")) {
                    if isSignedIn {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Signed in with Apple")
                                    .font(.headline)
                                Text("Securely authenticated")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button(action: {
                            showSignInSheet.toggle()
                        }) {
                            Label("Sign in with Apple", systemImage: "applelogo")
                        }
                        .sheet(isPresented: $showSignInSheet) {
                            SignInWithAppleView()
                        }
                    }
                }

                // APPEARANCE SECTION
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appearanceMode) {
                        Text("System").tag(AppearanceMode.system)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: appearanceMode) {
                        applyTheme()
                    }
                }

                // INTEGRATIONS SECTION
                Section(header: Text("Integrations")) {
                    NavigationLink("Tautulli", destination: integrationSettingsView(serviceName: "Tautulli"))
                    NavigationLink("Radarr", destination: integrationSettingsView(serviceName: "Radarr"))
                    NavigationLink("Sonarr", destination: integrationSettingsView(serviceName: "Sonarr"))
                    NavigationLink("Overseerr", destination: integrationSettingsView(serviceName: "Overseerr"))
                    NavigationLink("SabNZB", destination: integrationSettingsView(serviceName: "SabNZB"))
                    NavigationLink("Plex", destination: integrationSettingsView(serviceName: "Plex"))
                }

                // OTHER SETTINGS SECTION
                Section(header: Text("Other Settings")) {
                    Picker("Refresh Interval", selection: $refreshInterval) {
                        Text("10 sec").tag(10)
                        Text("30 sec").tag(30)
                        Text("60 sec").tag(60)
                        Text("2 min").tag(120)
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button("Clear Cache") {
                        print("Cache cleared!") // Placeholder for now
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                applyTheme()
            }
        }
    }

    // Integration Settings View for all integrations
    func integrationSettingsView(serviceName: String) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // API URL Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(serviceName) API URL")
                        .font(.headline)

                    TextField("Enter Instance URL", text: $apiURL)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 0.4))
                        .focused($focusedField, equals: .apiURL)
                        .onChange(of: apiURL) {
                            validateURL()
                        }

                    if !isURLValid {
                        Text("Invalid URL format. Example: https://example.com")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)

                // API Key Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(serviceName) API Key")
                        .font(.headline)

                    SecureField("Enter Instance API Key", text: $apiKey)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 0.4))
                        .focused($focusedField, equals: .apiKey)
                }
                .padding(.horizontal)

                // Test Connection Button
                Button(action: {
                    Task {
                        await testConnection()
                    }
                }) {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Test Connection")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(apiKey.isEmpty || !isURLValid || isTesting)
                .padding(.horizontal)

                // Connection Status Message
                if let status = connectionStatus {
                    Text(status)
                        .foregroundColor(status.contains("Success") ? .green : .red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Save Settings Button
                Button("Save Settings") {
                    saveSettings(serviceName: serviceName)  // Pass the service name here
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(apiKey.isEmpty || !isURLValid)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("\(serviceName) Settings")
        .ignoresSafeArea(.keyboard)
        .onAppear {
            loadSettings(serviceName: serviceName)  // Pass the service name here
        }
    }

    // URL Validation
    func validateURL() {
        let urlRegex = #"^(https?:\/\/)(localhost|\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b|([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(:\d+)?(\/.*)?$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", urlRegex)
        isURLValid = predicate.evaluate(with: apiURL)
    }

    // Test Connection to API
    func testConnection() async {
        guard let url = URL(string: "\(apiURL)/status") else {
            connectionStatus = "Invalid API URL"
            return
        }

        isTesting = true
        connectionStatus = nil

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                connectionStatus = "✅ Success: API is reachable"
            } else {
                connectionStatus = "❌ Failed: Invalid response"
            }
        } catch {
            connectionStatus = "❌ Failed: \(error.localizedDescription)"
        }

        isTesting = false
    }

    // Save API Settings
    func saveSettings(serviceName: String) {
        UserDefaults.standard.set(apiKey, forKey: "apiKey_\(serviceName)")
        UserDefaults.standard.set(apiURL, forKey: "apiURL_\(serviceName)")
        print("\(serviceName) API settings saved: \(apiURL), \(apiKey)")
    }

    // Load API Settings
    func loadSettings(serviceName: String) {
        apiKey = UserDefaults.standard.string(forKey: "apiKey_\(serviceName)") ?? ""
        apiURL = UserDefaults.standard.string(forKey: "apiURL_\(serviceName)") ?? ""
        validateURL()
    }
}

// Placeholder Sign-in with Apple view
struct SignInWithAppleView: View {
    var body: some View {
        VStack {
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        print("Authorization successful: \(authResults)")
                    case .failure(let error):
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
            )
            .frame(height: 45)
            .padding()
        }
    }
}

// Appearance Mode Enum
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

// Apply Theme Function
func applyTheme() {
    DispatchQueue.main.async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        switch UserDefaults.standard.string(forKey: "appearanceMode") ?? "system" {
        case "system":
            window.overrideUserInterfaceStyle = .unspecified
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            break
        }
    }
}

// Preview
#Preview {
    SettingsView()
}
