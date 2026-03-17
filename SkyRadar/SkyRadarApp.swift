import SwiftUI

@main
struct SkyRadarApp: App {
    @State private var viewModel = RadarViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
