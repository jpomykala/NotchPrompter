import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PrompterViewModel

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (build: \(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // MARK: - Text Section
                SectionHeader("Text", paddingTop: 0)

                TextEditor(text: $viewModel.text)
                    .font(.system(size: 14))
                    .frame(height: 140)
                    .padding(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )

                HStack(spacing: 12) {
                    Button(action: {
                        if(viewModel.isPlaying){
                            viewModel.pause()
                        } else {
                            viewModel.play()
                        }
                    }) {
                        Label(viewModel.isPlaying ? "Pause" : "Play",
                              systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .disabled(viewModel.voiceActivation)

                    Button(action: { viewModel.reset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }

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

                SettingSlider(
                    label: "Text size",
                    value: $viewModel.fontSize,
                    range: 8...30,
                    step: 1,
                    unit: "pt"
                )

                Toggle("Pause prompter on mouse hover", isOn: $viewModel.pauseOnHover)
                Toggle("Voice activation", isOn: $viewModel.voiceActivation)
                

                Divider()
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
                        // PROGRESS %
                        let rms = viewModel.audioMonitor?.rmsLevel ?? 0
                        let percentage = min(max(rms / 0.1, 0), 1.0) * 100

                        // BAR COLOR
                        let color: Color = rms > Float(viewModel.audioThreshold)
                            ? .green
                            : .red

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
        .navigationTitle("Preferences")
        .frame(width: 600, height: 600)
        .alert("Microphone access denied", isPresented: $viewModel.showMicrophoneAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable microphone access in System Preferences → Security & Privacy → Microphone.")
        }

    }
}


// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let paddingTop: CGFloat
    init(_ title: String, paddingTop: CGFloat = 0) { self.title = title
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Slider(value: $value, in: range, step: step)

                if unit == "%" {
                    Text("\(Int(value * 1000))%")
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
