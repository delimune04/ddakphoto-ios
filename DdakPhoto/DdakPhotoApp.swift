import SwiftUI

@main
struct DdakPhotoApp: App {
    init() {
        PhotoWorkspace.cleanPreviousSession()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
    }
}
