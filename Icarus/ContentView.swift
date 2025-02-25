//
//  ContentView.swift
//  Icarus
//
//  Created by Quentin Brooks on 2/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // iPhone Layout: TabView-based UI
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        } else {
            // iPad, macOS, tvOS, visionOS Layout: Sidebar-based UI
            NavigationSplitView {
                SidebarView()
            } detail: {
                HomeView()
            }
        }
    }
}

// Sidebar for iPad/macOS/tvOS/visionOS
struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink(destination: HomeView()) {
                Label("Home", systemImage: "house")
            }
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
        }
        .navigationTitle("Icarus")
    }
}

// Home Screen (Adaptive Grid/List)
struct HomeView: View {
    let items = Array(1...20) // Placeholder data

    var body: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns) {
                ForEach(items, id: \.self) { item in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(gradientForItem(item))
                        .frame(height: 100)
                        .overlay(Text("Item \(item)")
                            .foregroundColor(.white)
                            .bold())
                }
            }
            .padding()
        }
        .navigationTitle("Home")
    }

    var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150))]
    }
    
    
    func gradientForItem(_ item: Int) -> some ShapeStyle {
        if #available(iOS 17.0, macOS 14.0, *) {
            return MeshGradient(
                width: 150,
                height: 100,
                points: [
                    SIMD2<Float>(0, 0),
                    SIMD2<Float>(150, 0),
                    SIMD2<Float>(0, 100),
                    SIMD2<Float>(150, 100)
                ],
                colors: [.blue, .purple, .red]
            )
        } else {
            return Color.blue
        }
    }
}

// Settings Screen with Presentation Sizing Example
struct SettingsView: View {
    @State private var showInfo = false
    
    var body: some View {
        Form {
            Toggle("Enable Feature", isOn: .constant(true))
            Button("Show Info") {
                showInfo.toggle()
            }
            .sheet(isPresented: $showInfo) {
                InfoView()
                    // Use presentationDetents for adaptive modal sizing on iOS 16.4+ / iPadOS 16.4+
                    .presentationDetents([.medium, .large])
            }
            Button("Sign Out") {
                // Sign-out action
            }
        }
        .navigationTitle("Settings")
    }
}

struct InfoView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Information")
                .font(.headline)
            Text("More details about Icarus and its features.")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
