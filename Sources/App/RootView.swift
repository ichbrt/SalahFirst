import SwiftUI

/// Decides which of the three states the app is in.
///
/// The prayer window takes over the whole screen when one is open: at that
/// moment there is exactly one thing to say and one thing to do, and a tab bar
/// or a list underneath would only dilute it.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.preferences.hasCompletedOnboarding == false {
                OnboardingFlow()
            } else if let active = model.activeWindow {
                PrayerWindowView(active: active)
                    .transition(.opacity)
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.activeWindow)
        .animation(.easeInOut(duration: 0.25), value: model.preferences.hasCompletedOnboarding)
    }
}
