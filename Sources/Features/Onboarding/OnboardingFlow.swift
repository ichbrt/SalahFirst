import SwiftUI

/// Four steps, in the order the app actually needs them.
///
/// Kept short deliberately: a commitment device that opens with eight screens
/// of explanation has already spent the goodwill it needs later. Which prayers
/// are active, the calculation method and the window length all have workable
/// defaults and live in Settings.
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model
    @State private var step: Step = .welcome

    enum Step: Int, CaseIterable {
        case welcome, location, apps, ready
    }

    /// Which way the last move went, so the slide animation matches the
    /// direction of travel instead of always sliding forward.
    @State private var isMovingBack = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ProgressDots(count: Step.allCases.count, index: step.rawValue)

                HStack {
                    if step != .welcome {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.Palette.secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(L10n.string("common.back"))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.top, Theme.Spacing.xs)

            Group {
                switch step {
                case .welcome:  WelcomeStep(advance: advance)
                case .location: LocationStep(advance: advance)
                case .apps:     AppsStep(advance: advance)
                case .ready:    ReadyStep()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: isMovingBack ? .leading : .trailing).combined(with: .opacity),
                removal: .move(edge: isMovingBack ? .trailing : .leading).combined(with: .opacity)
            ))
        }
        .screenBackground()
        .animation(.easeInOut(duration: 0.25), value: step)
        .tint(Theme.Palette.accent)
        // A left-edge drag goes back, matching the system gesture people expect
        // from a navigation stack. Nothing here is irreversible, so there is no
        // reason to trap anyone on a step.
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    guard value.translation.width > 80,
                          abs(value.translation.height) < 60 else { return }
                    goBack()
                }
        )
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        isMovingBack = false
        step = next
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        isMovingBack = true
        step = previous
    }
}

private struct ProgressDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<count, id: \.self) { position in
                Capsule()
                    .fill(position == index ? Theme.Palette.accent : Theme.Palette.separator)
                    .frame(width: position == index ? 20 : 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(index + 1) / \(count)")
    }
}

/// Shared shape for every step: content that scrolls, actions pinned at the
/// bottom where the thumb is.
struct OnboardingStepLayout<Content: View, Actions: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    content
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: Theme.Spacing.xs) {
                actions
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.l)
        }
    }
}

// MARK: - 1. Welcome

private struct WelcomeStep: View {
    let advance: () -> Void

    var body: some View {
        OnboardingStepLayout {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                Spacer(minLength: Theme.Spacing.xl)
                SFHeader(
                    title: L10n.string("onboarding.welcome.title"),
                    subtitle: L10n.string("onboarding.welcome.body")
                )
            }
        } actions: {
            SFPrimaryButton(L10n.string("onboarding.welcome.action"), action: advance)
        }
    }
}

// MARK: - 2. Location

private struct LocationStep: View {
    @Environment(AppModel.self) private var model
    let advance: () -> Void

    @State private var isShowingCityPicker = false
    @State private var isRequesting = false

    var body: some View {
        OnboardingStepLayout {
            SFHeader(
                title: L10n.string("onboarding.location.title"),
                subtitle: L10n.string("onboarding.location.body")
            )

            if let location = model.preferences.prayerConfiguration.location {
                SFCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(location.name ?? L10n.string("settings.location.automatic"))
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.primary)
                        if let next = model.next {
                            Text("\(L10n.prayerName(next.prayer)) · \(Format.time(next.time))")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Palette.secondary)
                        }
                    }
                }
            }

            if model.location.isDenied {
                Text(L10n.string("status.location.denied.body"))
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } actions: {
            if model.preferences.prayerConfiguration.isComplete {
                SFPrimaryButton(L10n.string("common.continue"), action: advance)
                SFSecondaryButton(L10n.string("onboarding.location.manual")) {
                    isShowingCityPicker = true
                }
            } else {
                SFPrimaryButton(
                    L10n.string("onboarding.location.use"),
                    isEnabled: isRequesting == false && model.location.isDenied == false
                ) {
                    Task { await useCurrentLocation() }
                }
                SFSecondaryButton(L10n.string("onboarding.location.manual")) {
                    isShowingCityPicker = true
                }
            }
        }
        .sheet(isPresented: $isShowingCityPicker) {
            CityPickerView { city in
                Task {
                    await model.updateConfiguration { $0.location = city.location }
                }
            }
        }
    }

    private func useCurrentLocation() async {
        isRequesting = true
        defer { isRequesting = false }
        guard let fix = await model.location.requestLocation() else { return }
        await model.updateConfiguration {
            $0.location = PrayerLocation(
                latitude: fix.coordinate.latitude,
                longitude: fix.coordinate.longitude,
                name: nil,
                isAutomatic: true
            )
        }
    }
}

// MARK: - 3. Screen Time + app selection

private struct AppsStep: View {
    @Environment(AppModel.self) private var model
    let advance: () -> Void

    @State private var isRequesting = false

    var body: some View {
        OnboardingStepLayout {
            SFHeader(
                title: model.screenTime.isApproved
                    ? L10n.string("onboarding.apps.title")
                    : L10n.string("onboarding.screentime.title"),
                subtitle: model.screenTime.isApproved
                    ? L10n.string("onboarding.apps.body")
                    : L10n.string("onboarding.screentime.body")
            )

            if model.screenTime.isApproved {
                SFCard { AppSelectionSection() }
            }

            if ScreenTimeService.isSupportedOnThisDevice == false {
                SFCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(L10n.string("status.simulator.title"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Palette.primary)
                        Text(L10n.string("status.simulator.body"))
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if let error = model.screenTime.lastErrorMessage, error.isEmpty == false {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } actions: {
            if model.screenTime.isApproved {
                SFPrimaryButton(L10n.string("common.continue"), action: advance)
            } else {
                SFPrimaryButton(
                    L10n.string("onboarding.screentime.action"),
                    isEnabled: isRequesting == false
                ) {
                    Task {
                        isRequesting = true
                        await model.screenTime.requestAuthorization()
                        isRequesting = false
                    }
                }
                SFSecondaryButton(L10n.string("common.skip"), action: advance)
            }
        }
    }
}

// MARK: - 4. Ready

private struct ReadyStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        OnboardingStepLayout {
            SFHeader(
                title: L10n.string("onboarding.done.title"),
                subtitle: L10n.string("onboarding.done.body")
            )

            SFCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(L10n.string("onboarding.notifications.title"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Palette.primary)
                    Text(L10n.string("onboarding.notifications.body"))
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.notifications.isAuthorized == false {
                        Button(L10n.string("onboarding.notifications.action")) {
                            Task { await model.notifications.requestAuthorization() }
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.top, Theme.Spacing.xxs)
                    }
                }
            }
        } actions: {
            SFPrimaryButton(L10n.string("onboarding.done.action")) {
                Task { await finish() }
            }
        }
        .task { await model.notifications.refreshAuthorization() }
    }

    private func finish() async {
        // Blocking only switches itself on when there is actually something to
        // block — otherwise the home screen would claim to be protecting the
        // user while doing nothing.
        await model.updateBlocking { $0.isEnabled = $0.hasSelection }
        model.preferences.hasCompletedOnboarding = true
        await model.rebuildSchedule()
    }
}
