//
//  ContentView.swift
//  Icarus
//
//  Created by Quentin Brooks on 2/24/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedSidebarItem: SidebarItem? = .home

    var body: some View {
        if sizeClass == .compact {
            // iPhone Layout: TabView-based UI
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                            .accessibilityLabel("Home")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                            .accessibilityLabel("Settings")
                    }
            }
        } else {
            // iPad, macOS, tvOS, visionOS Layout: Sidebar-based UI
            NavigationSplitView {
                SidebarView(selectedItem: $selectedSidebarItem)
            } detail: {
                switch selectedSidebarItem {
                case .home:
                    HomeView()
                case .settings:
                    SettingsView()
                default:
                    Text("Select an option from the sidebar")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Sidebar Items Enum for Better Navigation Handling
enum SidebarItem: String, CaseIterable, Identifiable {
    case home, settings

    var id: String { rawValue }
}

// Sidebar View
struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?

    var body: some View {
        NavigationStack {
            List(selection: $selectedItem) {
                ForEach(SidebarItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue.capitalized, systemImage: item == .home ? "house" : "gear")
                    }
                }
            }
            .navigationTitle("Icarus")
        }
    }
}

// Preview
#Preview {
    ContentView()
}
