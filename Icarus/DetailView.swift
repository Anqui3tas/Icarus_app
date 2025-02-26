//
//  DetailView.swift
//  Icarus
//
//  Created by Quentin Brooks on 2/25/25.
//
import SwiftUI

struct DetailView: View {
    var itemTitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text(itemTitle)
                .font(.largeTitle)
                .bold()

            Text("Detailed information about \(itemTitle).")
                .foregroundStyle(.secondary)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle(itemTitle)
    }
}
