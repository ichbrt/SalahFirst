import SwiftUI

@main
struct SalahFirstApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Registration has to happen before launch completes, so it cannot wait
        // for a view to appear. The model is captured rather than recreated so
        // the background run writes to the same stores the UI reads.
        let model = _model.wrappedValue
        BackgroundRefreshService.register {
            await model.rebuildSchedule()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await model.handleForeground() }
            case .background:
                BackgroundRefreshService.scheduleNext()
            default:
                break
            }
        }
    }
}
