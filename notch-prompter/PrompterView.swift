import SwiftUI

struct PrompterView: View {
    @ObservedObject var viewModel: PrompterViewModel

    // Measure content height to stop appropriately
    @State private var contentHeight: CGFloat = 0

    // Tracks whether we paused due to hover and what the previous play state was
    @State private var wasPlayingBeforeHover: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        ScrollablePrompterView(
            viewModel: viewModel,
            contentHeight: $contentHeight,
            isHovering: $isHovering,
            wasPlayingBeforeHover: $wasPlayingBeforeHover
        )
    }
}

// MARK: Scrollable Prompter View with NSView for scroll events
struct ScrollablePrompterView: NSViewRepresentable {
    @ObservedObject var viewModel: PrompterViewModel
    @Binding var contentHeight: CGFloat
    @Binding var isHovering: Bool
    @Binding var wasPlayingBeforeHover: Bool

    func makeNSView(context: Context) -> PrompterHostingView {
        let hostingView = PrompterHostingView(
            viewModel: viewModel,
            contentHeight: $contentHeight,
            isHovering: $isHovering,
            wasPlayingBeforeHover: $wasPlayingBeforeHover
        )
        return hostingView
    }

    func updateNSView(_ nsView: PrompterHostingView, context: Context) {
        nsView.updateContent()
    }
}

// MARK: - Custom NSView to handle scroll events
class PrompterHostingView: NSView {
    private let viewModel: PrompterViewModel
    private var hostingView: NSHostingView<PrompterContentView>!
    private var trackingArea: NSTrackingArea?
    @Binding var contentHeight: CGFloat
    @Binding var isHovering: Bool
    @Binding var wasPlayingBeforeHover: Bool

    init(viewModel: PrompterViewModel,
         contentHeight: Binding<CGFloat>,
         isHovering: Binding<Bool>,
         wasPlayingBeforeHover: Binding<Bool>) {
        self.viewModel = viewModel
        self._contentHeight = contentHeight
        self._isHovering = isHovering
        self._wasPlayingBeforeHover = wasPlayingBeforeHover
        super.init(frame: .zero)

        let contentView = PrompterContentView(
            viewModel: viewModel,
            contentHeight: contentHeight
        )
        hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent() {
        let contentView = PrompterContentView(
            viewModel: viewModel,
            contentHeight: $contentHeight
        )
        hostingView.rootView = contentView
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways
        ]

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )

        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        handleHoverChange(hovering: true)
    }

    override func mouseExited(with event: NSEvent) {
        handleHoverChange(hovering: false)
    }

    override func scrollWheel(with event: NSEvent) {
        // Only handle scroll when hovering
        guard isHovering else { return }

        let scrollAmount = event.scrollingDeltaY
        let sensitivity: CGFloat = 100.0

        viewModel.offset = max(0, viewModel.offset - scrollAmount * sensitivity)
    }

    private func handleHoverChange(hovering: Bool) {
        guard viewModel.pauseOnHover else {
            isHovering = false
            wasPlayingBeforeHover = false
            return
        }

        if hovering {
            isHovering = true
            wasPlayingBeforeHover = viewModel.isPlaying
            if viewModel.isPlaying {
                viewModel.pause()
            }
        } else {
            if isHovering, wasPlayingBeforeHover {
                viewModel.play()
            }
            isHovering = false
            wasPlayingBeforeHover = false
        }
    }
}

// MARK: - Content View (SwiftUI)
struct PrompterContentView: View {
    @ObservedObject var viewModel: PrompterViewModel
    @Binding var contentHeight: CGFloat
    @State private var showControls = false

    var body: some View {
        ZStack {
            viewModel.prompterTheme.backgroundColor
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    movingText
                        .frame(width: geo.size.width, alignment: .center)
                        .offset(y: -viewModel.offset)
                        .background(HeightReader(height: $contentHeight))
                    Spacer(minLength: 0)
                }
                .clipped()
                .onChange(of: viewModel.text) { _, _ in
                    viewModel.offset = 0
                }
            }

            // Fade overlays
            VStack(spacing: 0) {
                if viewModel.enableTopFade {
                    LinearGradient(
                        gradient: Gradient(colors: [viewModel.prompterTheme.fadeColor, .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: viewModel.topFadeHeight)
                    .allowsHitTesting(false)
                }

                Spacer()

                if viewModel.enableBottomFade {
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, viewModel.prompterTheme.fadeColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: viewModel.bottomFadeHeight)
                    .allowsHitTesting(false)
                }
            }

            // Progress bar on the right side
            if viewModel.showProgressBar {
                HStack {
                    Spacer()
                    ProgressBarView(
                        currentOffset: viewModel.offset,
                        totalHeight: contentHeight,
                        theme: viewModel.prompterTheme
                    )
                }
            }

            // Hover controls overlay
            if showControls {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        // Play
                        if viewModel.voiceActivation {
                            Button(action: {
                                openSettingsWindow() // TODO: open voice settings
                            }) {
                                Image(systemName: "microphone.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.orange)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            }
                            .disabled(true)
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                if viewModel.isPlaying {
                                    viewModel.pause()
                                } else {
                                    viewModel.play()
                                }
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        // SCroll back
                        Button(action: {
                            viewModel.scrollBack()
                        }) {
                            Image(systemName: "backward.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Scroll back a few lines")

                        // Settings
                        Button(action: {
                            openSettingsWindow()
                        }) {
                            Image(systemName: "gearshape.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Open Settings")
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
                    .padding(.bottom, 2)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: showControls)
            }
        }
//        .opacity(viewModel.opacity) TODO: it would be better to control background and text opacity separatly, or just background opacity
        .ignoresSafeArea()
        .onHover { hovering in
            withAnimation {
                showControls = hovering
            }
        }
    }

    private func openSettingsWindow() {
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)

        // Try to find existing settings window first
        for window in NSApp.windows {
            if window.title == "NotchPrompter" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        // Simulate the Command+, keyboard shortcut which opens Settings
        let keyDown = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: .command,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            characters: ",",
            charactersIgnoringModifiers: ",",
            isARepeat: false,
            keyCode: 43 // Key code for comma
        )

        if let event = keyDown {
            NSApp.postEvent(event, atStart: true)
        }
    }

    private var movingText: some View {
        return VStack(spacing: viewModel.lineHeight) {
            textBlock
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private var textBlock: some View {
        let base = viewModel.text.isEmpty ? "Put some text in Settings..." : viewModel.text
        let text = "\n" + base + "\n\n[the end]"

        return Text(attributedText(from: text))
            .multilineTextAlignment(viewModel.textAlignment.swiftUIAlignment)
            .lineSpacing(viewModel.lineHeight)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func attributedText(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // Default font and color
        let defaultFont = Font.system(size: viewModel.fontSize, weight: .regular, design: viewModel.fontDesign)
        let defaultColor = viewModel.prompterTheme.textColor

        // Apply default attributes to entire string
        attributedString.font = defaultFont
        attributedString.foregroundColor = defaultColor

        // Find and style text in [brackets]
        let pattern = "\\[[^\\]]+\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let range = match.range
                if let stringRange = Range(range, in: text) {
                    let attributedRange = Range(stringRange, in: attributedString)
                    if let attributedRange = attributedRange {
                        // Make annotation text italic and dimmed
                        attributedString[attributedRange].font = Font.system(size: viewModel.fontSize, weight: .regular, design: viewModel.fontDesign).italic()
                        attributedString[attributedRange].foregroundColor = viewModel.prompterTheme.textColor.opacity(0.4)
                    }
                }
            }
        }

        return attributedString
    }
}

// MARK: - Height reader
private struct HeightReader: View {
    @Binding var height: CGFloat
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { height = proxy.size.height }
                .onChange(of: proxy.size) { _, newSize in
                    height = newSize.height
                }
        }
    }
}


// MARK: - Progress bar
struct ProgressBarView: View {
    let currentOffset: CGFloat
    let totalHeight: CGFloat
    let theme: PrompterTheme

    private var progress: Double {
        guard totalHeight > 0 else { return 0 }
        return min(max(Double(currentOffset / totalHeight), 0), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.textColor.opacity(0.15))
                    .frame(width: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.textColor.opacity(0.6))
                    .frame(width: 4, height: geo.size.height * progress)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 4)
        .padding(.trailing, 6)
        .padding(.bottom, 8)
        .padding(.vertical, 8)
        .allowsHitTesting(false)
    }
}
