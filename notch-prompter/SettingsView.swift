import SwiftUI

// MARK: - Settings Tabs
enum SettingsTab: String, CaseIterable, Identifiable {
    case script = "Script"
    case appearance = "Appearance"
    case behavior = "Behavior"
    case voice = "Voice"
    case layout = "Layout"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .script: return "doc.text"
        case .appearance: return "paintpalette"
        case .behavior: return "gearshape"
        case .voice: return "waveform"
        case .layout: return "macwindow"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: PrompterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .script

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (build: \(build))"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                // TODO: It would be cool to put here NotchPrompter + version instead of having this in the footer, but I have to also get rid of the window handler with "NotchPrompter Settings" to make it look good.
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)

                ForEach(SettingsTab.allCases) { tab in
                    HStack(spacing: 7) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 16)
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .regular))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTab = tab
                    }
                }

                Spacer()
            }
            .padding(12)
            .frame(width: 160)
            .frame(maxHeight: .infinity)
            .background(Color.primary.opacity(0.04))

            Divider()

            // Content
            VStack(spacing: 0) {
                switch selectedTab {
                case .script:
                    ScriptTabView(viewModel: viewModel)
                case .appearance:
                    AppearanceTabView(viewModel: viewModel)
                case .behavior:
                    BehaviorTabView(viewModel: viewModel)
                case .voice:
                    VoiceTabView(viewModel: viewModel)
                case .layout:
                    LayoutTabView(viewModel: viewModel)
                }

                Divider()

                HStack {
                    Text("NotchPrompter \(appVersion)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .opacity(0.3)
                    
                    Spacer()
                    
                    Button {
                        if viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            viewModel.play()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(viewModel.isPlaying ? "Pause" : "Play")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.voiceActivation)
                    
                    Button {
                        viewModel.reset()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                            Text("Reset")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderless)

                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 680)
        .frame(minHeight: 560, maxHeight: 760)
        .background(.ultraThinMaterial)
        .alert("Microphone access denied", isPresented: $viewModel.showMicrophoneAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable microphone access in System Settings → Privacy & Security → Microphone.")
        }
    }
}

// MARK: - Script Tab
struct ScriptTabView: View {
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
                
                // Placeholder
                if viewModel.text.isEmpty {
                    Text("Type your script here...\n\nUse [brackets] for stage directions like [pause], [smile], etc.")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                HighlightingTextEditor(
                    text: $viewModel.text,
                    font: .systemFont(ofSize: 15, weight: .regular),
                    isFocused: $isTextEditorFocused
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Highlighting Text Editor
struct HighlightingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 15, weight: .regular)
    var isFocused: FocusState<Bool>.Binding?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 5, height: 4)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = font
        textView.delegate = context.coordinator
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        // Set initial text and apply highlighting
        textView.string = text
        context.coordinator.applyHighlighting(textView)
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyHighlighting(textView)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightingTextEditor
        weak var textView: NSTextView?
        
        private static let annotationPattern = try! NSRegularExpression(
            pattern: "\\[[^\\]]+\\]",
            options: []
        )
        
        init(_ parent: HighlightingTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyHighlighting(textView)
        }
        
        func applyHighlighting(_ textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: textStorage.length)
            let text = textStorage.string
            
            // Preserve selection
            let selectedRanges = textView.selectedRanges
            
            textStorage.beginEditing()
            
            // Reset to default style
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: parent.font,
                .foregroundColor: NSColor.labelColor
            ]
            textStorage.setAttributes(defaultAttributes, range: fullRange)
            
            // Highlight [bracket] annotations
            let matches = Self.annotationPattern.matches(in: text, options: [], range: fullRange)
            for match in matches {
                let annotationAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFontManager.shared.convert(parent.font, toHaveTrait: .italicFontMask),
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.08)
                ]
                textStorage.addAttributes(annotationAttributes, range: match.range)
            }
            
            textStorage.endEditing()
            
            // Restore selection
            textView.selectedRanges = selectedRanges
        }
    }
}

// MARK: - Appearance Tab
struct AppearanceTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Font")
                    .font(.system(size: 13, weight: .medium))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Style")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $viewModel.fontDesign) {
                        ForEach([Font.Design.default, .serif, .rounded, .monospaced], id: \.self) { design in
                            Text(design.displayName).tag(design)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                SettingSlider(
                    label: "Size",
                    value: $viewModel.fontSize,
                    range: 8...30,
                    step: 1,
                    unit: "pt"
                )
                
                SettingSlider(
                    label: "Line spacing",
                    value: $viewModel.lineHeight,
                    range: 0...20,
                    step: 1,
                    unit: "pt"
                )
                
                Divider()
                
                Text("Theme")
                    .font(.system(size: 13, weight: .medium))
                
                Picker("", selection: $viewModel.prompterTheme) {
                    ForEach(PrompterTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Divider()
                
                Text("Fade Effects")
                    .font(.system(size: 13, weight: .medium))
                
                HStack(alignment: .top, spacing: 10) {
                    Toggle("", isOn: $viewModel.enableTopFade)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    
                    VStack(alignment: .leading) {
                        Text("Top fade")
                            .font(.system(size: 13))
                        Text("Fade out content at the top of the prompter")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if viewModel.enableTopFade {
                    SettingSlider(
                        label: "Height",
                        value: $viewModel.topFadeHeight,
                        range: 10...150,
                        step: 5,
                        unit: "px"
                    )
                }
                
                HStack(alignment: .top, spacing: 10) {
                    Toggle("", isOn: $viewModel.enableBottomFade)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    
                    VStack(alignment: .leading) {
                        Text("Bottom fade")
                            .font(.system(size: 13))
                        Text("Fade out content at the bottom of the prompter")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if viewModel.enableBottomFade {
                    SettingSlider(
                        label: "Height",
                        value: $viewModel.bottomFadeHeight,
                        range: 10...150,
                        step: 5,
                        unit: "px"
                    )
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Behavior Tab
struct BehaviorTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SettingSlider(
                    label: "Scroll speed",
                    value: $viewModel.speed,
                    range: 1...40,
                    step: 1,
                    unit: "pt/s"
                )
                
                Divider()
                
                Text("Mouse Interaction")
                    .font(.system(size: 13, weight: .medium))
                
                Toggle(isOn: $viewModel.pauseOnHover) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pause on hover")
                            .font(.system(size: 13))
                        Text("Pause scrolling when mouse enters the prompter window")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $viewModel.showHoverControls) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show controls on hover")
                            .font(.system(size: 13))
                        Text("Display play/pause controls when hovering")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                
                Divider()
                
                Text("Privacy")
                    .font(.system(size: 13, weight: .medium))
                
                Toggle(isOn: $viewModel.hideFromScreenRecording) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide from screen recordings")
                            .font(.system(size: 13))
                        Text("Prevent the prompter from appearing in screen shares")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .padding(16)
        }
    }
}

// MARK: - Voice Tab
struct VoiceTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Toggle("", isOn: $viewModel.voiceActivation)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice activation")
                            .font(.system(size: 13, weight: .medium))
                        Text("Automatically scroll when speaking is detected")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if viewModel.voiceActivation {
                    Divider()
                    
                    SettingSlider(
                        label: "Detection threshold",
                        value: Binding(
                            get: { Double(viewModel.audioThreshold) },
                            set: { viewModel.audioThreshold = Float($0) }
                        ),
                        range: 0.0...0.1,
                        step: 0.005,
                        unit: "%"
                    )
                    
                    Text("Adjust sensitivity for voice detection. Lower values detect quieter speech.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Audio level monitor")
                            .font(.system(size: 12))
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
                    
                    Text("Speak to test your microphone levels")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Layout Tab
struct LayoutTabView: View {
    @ObservedObject var viewModel: PrompterViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Window")
                    .font(.system(size: 13, weight: .medium))
                
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
                
                Divider()
                
                Text("Display")
                    .font(.system(size: 13, weight: .medium))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Screen")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $viewModel.selectedScreenIndex) {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                            Text("\(screen.localizedName) (\(index + 1))").tag(index)
                        }
                    }
                    .labelsHidden()
                }
                
                Text("Choose which screen the prompter appears on")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
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
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                if unit == "%" && !isPercentage {
                    Text("\(Int(value * 1000))%")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                } else if isPercentage {
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("\(Int(value)) \(unit)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}
