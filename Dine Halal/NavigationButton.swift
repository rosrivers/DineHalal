

/// Handles redeclaration of navigationbutton function in Review and homescreen.
/// NavigationButton.swift
/// Dine Halal
///  Created by Joanne on 3/19/25.

import SwiftUI

struct NavigationButton<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: icon)
                Text(title)
                    .font(.footnote)
            }
            .padding()
        }
    }
}
