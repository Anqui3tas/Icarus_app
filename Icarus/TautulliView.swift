import SwiftUI

struct TautulliView: View {
    @State private var sessions: [TautulliSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("refreshInterval") private var refreshInterval: Int = 30
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Loading Tautulli activity...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    ForEach(sessions) { session in
                        HStack {
                            if let thumbURL = session.fullThumbURL {
                                AsyncImage(url: thumbURL) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading) {
                                Text(session.title)
                                    .font(.headline)
                                Text("User: \(session.user)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let progress = session.progressPercent {
                                    ProgressView(value: progress / 100)
                                        .frame(maxWidth: 100)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tautulli Activity")
            .onAppear {
                startAutoRefresh()
                Task { await fetchTautulliData() }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await fetchTautulliData() }
                }
            }
            .onChange(of: refreshInterval) { _, _ in
                startAutoRefresh()
            }
        }
    }

    // ✅ Start Auto-Refresh (Keeps Retrying)
    func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { _ in
            Task { await fetchTautulliData() }
        }
    }

    // ✅ Fetch Tautulli Data with Continuous Retry
    func fetchTautulliData() async {
        guard let apiURL = UserDefaults.standard.string(forKey: "apiURL_Tautulli"),
              let apiKey = UserDefaults.standard.string(forKey: "apiKey_Tautulli"),
              !apiURL.isEmpty, !apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Tautulli API is not configured."
                self.isLoading = false
            }
            return
        }

        let urlString = "\(apiURL)/api/v2?cmd=get_activity&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid API URL."
                self.isLoading = false
            }
            return
        }

        do {
            // Log the URL for debugging
            print("Fetching Tautulli data from URL: \(urlString)")

            let (data, response) = try await URLSession.shared.data(from: url)

            // Debugging response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }

            // Check for server response status
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Server returned an error: \(response)"
                    self.isLoading = false
                }
                throw URLError(.badServerResponse)
            }

            let decodedResponse = try JSONDecoder().decode(TautulliResponse.self, from: data)
            DispatchQueue.main.async {
                self.sessions = decodedResponse.response.data.sessions
                self.errorMessage = nil
                self.isLoading = false
            }
        } catch {
            // Log the error for debugging
            print("Error fetching data: \(error)")

            DispatchQueue.main.async {
                self.errorMessage = "Network error: Retrying in \(refreshInterval) sec..."
                self.isLoading = false
            }
        }
    }
}

// ✅ Tautulli API
struct TautulliAPI {
    static func fetchActivity(apiURL: String, apiKey: String) async throws -> [TautulliSession] {
        guard let url = URL(string: "\(apiURL)/api/v2?cmd=get_activity&apikey=\(apiKey)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(TautulliResponse.self, from: data)
        return decodedResponse.response.data.sessions
    }
}

// ✅ Tautulli Data Models
struct TautulliResponse: Codable {
    let response: TautulliData
}

struct TautulliData: Codable {
    let data: TautulliSessions
}

struct TautulliSessions: Codable {
    let sessions: [TautulliSession]
}

struct TautulliSession: Identifiable, Codable {
    let id = UUID() // UUID generated for each session
    let title: String
    let user: String
    let progressPercent: Double?
    let thumb: String?

    // Construct full image URL
    var fullThumbURL: URL? {
        guard let apiURL = UserDefaults.standard.string(forKey: "apiURL_Tautulli"),
              let thumbPath = thumb, !thumbPath.isEmpty else { return nil }
        return URL(string: "\(apiURL)\(thumbPath)")
    }

    enum CodingKeys: String, CodingKey {
        case title, user, progressPercent = "progress_percent", thumb
    }
}

// ✅ Preview
#Preview {
    TautulliView()
}
