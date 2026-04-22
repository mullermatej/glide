//
//  GlideApp.swift
//  Glide
//
//  Created by Matej Muller on 19.03.2026..
//

import SwiftUI
import Supabase

@main
struct GlideApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                AuthenticatedRootView(auth: auth)
            } else {
                AuthView(auth: auth)
            }
        }
    }
}

struct AuthenticatedRootView: View {
    var auth: AuthViewModel
    @State private var profileVM = ProfileViewModel()
    @State private var hasLoaded = false

    private var needsOnboarding: Bool {
        let name = profileVM.profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty
    }

    var body: some View {
        Group {
            if !hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if needsOnboarding {
                ProfileSetupView(vm: profileVM)
            } else {
                GroupListView(auth: auth)
            }
        }
        .task(id: auth.session?.user.id) {
            hasLoaded = false
            await profileVM.fetchProfile()
            hasLoaded = true
        }
    }
}
