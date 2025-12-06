import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PrompterViewModel

    var body: some View {
        
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Text Editor with Play/Pause button
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $viewModel.text)
                        .font(.system(size: 14))
                        .frame(minHeight: 120, maxHeight: 200)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    
                    Button(action: { viewModel.isPlaying.toggle() }) {
                        Label(viewModel.isPlaying ? "Pause" : "Play",
                              systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .cornerRadius(8)
                    }
                    .padding(8)
                }
                
                // MARK: - Sliders in two columns
                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 16) {
                        SettingSlider(label: "Speed", value: $viewModel.speed, range: 1...40, unit: "pt/s")
                        SettingSlider(label: "Text size", value: $viewModel.fontSize, range: 8...30, unit: "pt")
                    }
                    
                    VStack(spacing: 16) {
                        SettingSlider(
                            label: "Prompter width",
                            value: Binding(
                                get: { Double(viewModel.prompterWidth) },
                                set: { viewModel.prompterWidth = CGFloat($0) }
                            ),
                            range: 100...600,
                            unit: "px"
                        )
                        SettingSlider(
                            label: "Prompter height",
                            value: Binding(
                                get: { Double(viewModel.prompterHeight) },
                                set: { viewModel.prompterHeight = CGFloat($0) }
                            ),
                            range: 100...500,
                            unit: "px"
                        )
                    }
                }
                
                // MARK: - Toggle
                Toggle("Pause prompter on mouse hover", isOn: $viewModel.pauseOnHover)
                    .toggleStyle(.checkbox)
                
                Spacer(minLength: 20)
            }
            .padding()
        
        .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 24) // adds top inset
            }
        .frame(minWidth: 600, minHeight: 500)
        .navigationTitle("Preferences")
    }
}

struct SettingSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Slider(value: $value, in: range, step: 1)
                Text("\(Int(value)) \(unit)")
                    .monospacedDigit()
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }
}
