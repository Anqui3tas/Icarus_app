import SwiftUI

struct HomeView: View {
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

        do {
            let fetchedSessions = try await TautulliAPI.fetchActivity(apiURL: apiURL, apiKey: apiKey)
            DispatchQueue.main.async {
                self.sessions = fetchedSessions
                self.errorMessage = nil
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Network error: Retrying in \(refreshInterval) sec..."
                self.isLoading = false
            }
        }
    }
}

// ✅ Preview
#Preview {
    HomeView()
}
