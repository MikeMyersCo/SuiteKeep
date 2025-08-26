//
//  SuiteKeepApp.swift
//  SuiteKeep
//
//  Created by Mike Myers on 7/30/25.
//

import SwiftUI

@main
struct SuiteKeepApp: App {
    @StateObject private var sharedSuiteManager = SharedSuiteManager()
    @State private var incomingInvitation: String?
    @State private var showingInvitationAlert = false
    
    var body: some Scene {
        WindowGroup {
            DynamicFireSuiteApp()
                .environmentObject(sharedSuiteManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .alert("Suite Invitation", isPresented: $showingInvitationAlert) {
                    Button("Accept") {
                        if let tokenId = incomingInvitation {
                            Task {
                                try? await sharedSuiteManager.joinSuiteWithInvitation(tokenId)
                            }
                        }
                    }
                    Button("Decline", role: .cancel) {
                        incomingInvitation = nil
                    }
                } message: {
                    Text("You've been invited to join a shared suite. Would you like to accept?")
                }
        }
        .handlesExternalEvents(matching: ["suitekeep"])
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle suite invitation URLs
        // Format: suitekeep://invite/{tokenId}
        // Or: https://suitekeep.app/invite/{tokenId}
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        // Handle custom scheme (suitekeep://)
        if url.scheme == "suitekeep" {
            if url.host == "invite", url.pathComponents.count >= 2 {
                let tokenId = url.pathComponents[1]
                handleInvitation(tokenId: tokenId)
            }
        }
        // Handle universal link (https://suitekeep.app)
        else if url.scheme == "https" && url.host == "suitekeep.app" {
            if url.pathComponents.count >= 3 && url.pathComponents[1] == "invite" {
                let tokenId = url.pathComponents[2]
                handleInvitation(tokenId: tokenId)
            }
        }
    }
    
    private func handleInvitation(tokenId: String) {
        incomingInvitation = tokenId
        showingInvitationAlert = true
    }
}
