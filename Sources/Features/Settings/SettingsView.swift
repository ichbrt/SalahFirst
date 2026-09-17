import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingCityPicker = false
    @State private var isConfirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                blockingSection
                timesSection
                asrSection
                notificationsSection
                aboutSection
                resetSection
            }
            // The stock Form background is a system grey that belongs to no
            // app in particular. Hiding it lets Settings sit on the same
            // surface — and the same quiet pattern — as everything else.
            .scrollContentBackground(.hidden)
            .patternedBackground(fadeHeight: 420)
            .navigationTitle(L10n.string("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.done")) { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingCityPicker) {
                CityPickerView { city in
                    Task { await model.updateConfiguration { $0.location = city.location } }
                }
            }
            .confirmationDialog(
                L10n.string("settings.reset"),
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button(L10n.string("settings.reset.confirm"), role: .destructive) {
                    Task {
                        await model.resetEverything()
                        dismiss()
                    }
                }
                Button(L10n.string("common.cancel"), role: .cancel) {}
            } message: {
                Text(L10n.string("settings.reset.footer"))
            }
        }
        .tint(Theme.Palette.accent)
    }

    // MARK: - Blocking

    private var blockingSection: some View {
        Section {
            Toggle(L10n.string("settings.blocking.enabled"), isOn: blockingEnabled)
                .tint(Theme.Palette.accent)
                .disabled(model.screenTime.isApproved == false || model.blocking.hasSelection == false)

            if model.screenTime.isApproved {
                AppSelectionSection()
            } else {
                Button(L10n.string("onboarding.screentime.action")) {
                    Task {
                        await model.screenTime.requestAuthorization()
                        await model.rebuildSchedule()
                    }
                }
            }

            NavigationLink(L10n.string("settings.prayers")) {
                Form { PrayerToggleList() }
                    .navigationTitle(L10n.string("settings.prayers"))
                    .navigationBarTitleDisplayMode(.inline)
            }

            Picker(L10n.string("settings.window"), selection: windowMinutes) {
                ForEach(windowOptions, id: \.self) { minutes in
                    Text(L10n.string("common.minutesShort", minutes)).tag(minutes)
                }
            }
        } header: {
            Text(L10n.string("settings.section.blocking"))
        } footer: {
            Text(model.screenTime.isApproved
                 ? L10n.string("settings.window.footer")
                 : L10n.string("status.screentime.denied.body"))
        }
    }

    /// Only values the system will accept: at least fifteen minutes, and long
    /// enough to be useful without running into the next prayer.
    private var windowOptions: [Int] {
        stride(from: BlockingSettings.minimumWindowMinutes,
               through: BlockingSettings.maximumWindowMinutes,
               by: 5).map { $0 }
    }

    private var blockingEnabled: Binding<Bool> {
        Binding(
            get: { model.blocking.isEnabled },
            set: { isOn in Task { await model.updateBlocking { $0.isEnabled = isOn } } }
        )
    }

    private var windowMinutes: Binding<Int> {
        Binding(
            get: { model.blocking.clampedWindowMinutes },
            set: { value in Task { await model.updateBlocking { $0.windowMinutes = value } } }
        )
    }

    // MARK: - Prayer times

    private var timesSection: some View {
        Section {
            Button {
                isShowingCityPicker = true
            } label: {
                HStack {
                    Text(L10n.string("settings.location"))
                        .foregroundStyle(Theme.Palette.primary)
                    Spacer()
                    Text(locationSummary)
                        .foregroundStyle(Theme.Palette.secondary)
                }
            }

            Picker(L10n.string("settings.method"), selection: method) {
                ForEach(CalculationMethodOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.navigationLink)

        } header: {
            Text(L10n.string("settings.section.times"))
        }
    }

    /// Asr is the one prayer whose time depends on a choice, and the two
    /// options can sit an hour apart.
    ///
    /// The options are labelled by the time they produce rather than by the
    /// school of thought behind them. Only two distinct times exist — the
    /// Shafi, Maliki, Hanbali and Jafari calculations all give the earlier one —
    /// so naming four schools would imply a precision that is not there. And
    /// asking someone to declare a madhab inside a screen-time tool is a
    /// heavier question than the setting deserves. Showing both clock times
    /// lets people pick the one they already recognise.
    private var asrSection: some View {
        Section {
            Picker(selection: madhab) {
                ForEach(MadhabOption.allCases) { option in
                    HStack {
                        Text(L10n.string(option.nameKey))
                        Spacer()
                        if let time = asrTime(for: option) {
                            Text(time)
                                .monospacedDigit()
                                .foregroundStyle(Theme.Palette.secondary)
                        }
                    }
                    .tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } header: {
            Text(L10n.string("settings.madhab"))
        } footer: {
            Text(L10n.string("settings.madhab.footer"))
        }
    }

    /// Today's Asr for a given option, so the user can choose by the clock
    /// rather than by the terminology.
    private func asrTime(for option: MadhabOption) -> String? {
        var configuration = model.preferences.prayerConfiguration
        configuration.madhab = option
        guard let time = PrayerTimesEngine(configuration: configuration)
            .times(on: model.now)?.time(for: .asr) else { return nil }
        return Format.time(time)
    }

    private var locationSummary: String {
        guard let location = model.preferences.prayerConfiguration.location else {
            return L10n.string("settings.location.none")
        }
        if let name = location.name { return name }
        return location.isAutomatic
            ? L10n.string("settings.location.automatic")
            : L10n.string("settings.location.manual")
    }

    private var method: Binding<CalculationMethodOption> {
        Binding(
            get: { model.preferences.prayerConfiguration.method },
            set: { value in Task { await model.updateConfiguration { $0.method = value } } }
        )
    }

    private var madhab: Binding<MadhabOption> {
        Binding(
            get: { model.preferences.prayerConfiguration.madhab },
            set: { value in Task { await model.updateConfiguration { $0.madhab = value } } }
        )
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(L10n.string("settings.notifications.enabled"), isOn: notificationsEnabled)
                .tint(Theme.Palette.accent)
        } header: {
            Text(L10n.string("settings.section.notifications"))
        }
    }

    private var notificationsEnabled: Binding<Bool> {
        Binding(
            get: { model.preferences.notificationsEnabled },
            set: { isOn in
                model.preferences.notificationsEnabled = isOn
                Task {
                    if isOn { await model.notifications.requestAuthorization() }
                    await model.rebuildSchedule()
                }
            }
        )
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            NavigationLink(L10n.string("settings.privacy")) { PrivacyView() }
            LabeledContent(L10n.string("settings.version"), value: Self.versionString)
        } header: {
            Text(L10n.string("settings.section.about"))
        }
    }

    private static var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button(L10n.string("settings.reset"), role: .destructive) {
                isConfirmingReset = true
            }
        } header: {
            Text(L10n.string("settings.section.danger"))
        } footer: {
            Text(L10n.string("settings.reset.footer"))
        }
    }
}
