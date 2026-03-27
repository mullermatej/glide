//
//  GlideApp.swift
//  Glide
//
//  Created by Matej Muller on 19.03.2026..
//

import SwiftUI

@main
struct GlideApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                ContentView()
                    .environment(auth)
            } else {
                AuthView(auth: auth)
            }
        }
    }
}
