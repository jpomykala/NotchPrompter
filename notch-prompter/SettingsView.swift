import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PrompterViewModel
    @State private var selectedTab: SettingsTab = .text

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (build: \(build))"
    }
    
    enum SettingsTab: String, CaseIterable {
        case text = "Script"
        case settings = "Settings"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            HStack(spacing: 12) {
                Button {
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                } label: {
                    Label(viewModel.isPlaying ? "Pause" : "Play",
                          systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(viewModel.voiceActivation)
                
                Divider()
                    .frame(height: 20)
                
                Button {
                    viewModel.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                
                Button {
                    viewModel.isPrompterVisible.toggle()
                } label: {
                    Label(viewModel.isPrompterVisible ? "Hide" : "Show",
                          systemImage: viewModel.isPrompterVisible ? "eye.slash" : "eye")
                }
                
                Spacer()
                
                // Tab picker in toolbar
                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.palette)
                
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Tab content
            Group {
                switch selectedTab {
                case .text:
                    TextTabView(viewModel: viewModel)
                case .settings:
                    SettingsTabView(viewModel: viewModel, appVersion: appVersion)
                }
            }
        }
        .navigationTitle("NotchPrompter")
        .frame(width: 650, height: 650)
        .alert("Microphone access denied", isPresented: $viewModel.showMicrophoneAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable microphone access in System Preferences → Security & Privacy → Microphone.")
        }
    }
}

// MARK: - Text Tab
struct TextTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isTextEditorFocused ? Color.accentColor : Color(nsColor: .separatorColor),
                                lineWidth: isTextEditorFocused ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
                
                // Placeholder (TODO: is there any better option?)
                if viewModel.text.isEmpty {
                    Text("Start typing your script here...")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $viewModel.text)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isTextEditorFocused)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    let appVersion: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // MARK: - Appearance Section
                SectionHeader("Appearance", paddingTop: 0)
                
                SettingSlider(
                    label: "Text size",
                    value: $viewModel.fontSize,
                    range: 8...30,
                    step: 1,
                    unit: "pt"
                )
                
                SettingSlider(
                    label: "Window opacity",
                    value: $viewModel.opacity,
                    range: 0.1...1.0,
                    step: 0.05,
                    unit: "%",
                    isPercentage: true
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Font style")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Font style", selection: $viewModel.fontDesign) {
                        Text("Default").tag(Font.Design.default)
                        Text("Serif").tag(Font.Design.serif)
                        Text("Rounded").tag(Font.Design.rounded)
                        Text("Monospaced").tag(Font.Design.monospaced)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 2)
                
                Divider()
                
                // MARK: - Fade Effects Section
                SectionHeader("Fade Effects")
                
                Toggle("Enable top fade", isOn: $viewModel.enableTopFade)
                
                if viewModel.enableTopFade {
                    SettingSlider(
                        label: "Top fade height",
                        value: $viewModel.topFadeHeight,
                        range: 10...150,
                        step: 5,
                        unit: "px"
                    )
                    .padding(.leading, 20)
                }
                
                Toggle("Enable bottom fade", isOn: $viewModel.enableBottomFade)
                
                if viewModel.enableBottomFade {
                    SettingSlider(
                        label: "Bottom fade height",
                        value: $viewModel.bottomFadeHeight,
                        range: 10...150,
                        step: 5,
                        unit: "px"
                    )
                    .padding(.leading, 20)
                }
                
                Text("Tip: Fade effects create a smooth gradient overlay at the top and/or bottom of the prompter for a more polished, professional appearance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                Divider()

                // MARK: - Behavior Section
                SectionHeader("Behavior")

                SettingSlider(
                    label: "Scroll speed",
                    value: $viewModel.speed,
                    range: 1...40,
                    step: 1,
                    unit: "pt/s"
                )

                Toggle("Pause prompter on mouse hover", isOn: $viewModel.pauseOnHover)
                
                Text("Tip: When hovering over the prompter with pause enabled, you can use your mouse wheel or trackpad to manually scroll up and down through the text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                
                Toggle("Show hover controls", isOn: $viewModel.showHoverControls)
                
                Text("Tip: When enabled, play/pause, back, and settings buttons appear at the bottom of the prompter when you hover over it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                
                Toggle("Voice activation", isOn: $viewModel.voiceActivation)
                
                Divider()
                
                // MARK: - Voice Activation Section
                SectionHeader("Voice activation")
                
                Toggle("Automatic gain control", isOn: $viewModel.autoGain)
                
                SettingSlider(
                    label: "Detection Threshold",
                    value: Binding(
                        get: { Double(viewModel.audioThreshold) },
                        set: { viewModel.audioThreshold = Float($0) }
                    ),
                    range: 0.0...0.1,
                    step: 0.005,
                    unit: "%"
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        let rms = viewModel.audioMonitor?.rmsLevel ?? 0
                        let percentage = min(max(rms / 0.1, 0), 1.0) * 100
                        let color: Color = rms > Float(viewModel.audioThreshold) ? .green : .red

                        ProgressView(value: percentage / 100)
                            .progressViewStyle(
                                LinearProgressViewStyle(tint: color)
                            )
                            .frame(height: 10)

                        Text("\(Int(percentage))%")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .padding(.vertical, 2)
                
                Divider()

                // MARK: - Layout Section
                SectionHeader("Prompter Layout")
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display screen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Display screen", selection: $viewModel.selectedScreenIndex) {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                            Text("\(screen.localizedName) (\(index + 1))").tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.vertical, 2)

                SettingSlider(
                    label: "Width",
                    value: Binding(
                        get: { Double(viewModel.prompterWidth) },
                        set: { viewModel.prompterWidth = CGFloat($0) }
                    ),
                    range: 150...600,
                    step: 10,
                    unit: "px"
                )

                SettingSlider(
                    label: "Height",
                    value: Binding(
                        get: { Double(viewModel.prompterHeight) },
                        set: { viewModel.prompterHeight = CGFloat($0) }
                    ),
                    range: 20...500,
                    step: 10,
                    unit: "px"
                )

                Spacer(minLength: 12)
                
                Divider()

                HStack {
                    Text("NotchPrompter \(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let paddingTop: CGFloat
    
    init(_ title: String, paddingTop: CGFloat = 12) {
        self.title = title
        self.paddingTop = paddingTop
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, paddingTop)
    }
}


// MARK: - Slider Component
struct SettingSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    var isPercentage: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Slider(value: $value, in: range, step: step)

                if unit == "%" && !isPercentage {
                    Text("\(Int(value * 1000))%")
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                } else if isPercentage {
                    Text("\(Int(value * 100))%")
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                } else {
                    Text("\(Int(value)) \(unit)")
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
