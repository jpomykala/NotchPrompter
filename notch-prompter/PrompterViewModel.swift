import Foundation
import Combine
import CoreVideo
import AVFoundation
import Accelerate
import SwiftUI
import HotKey

final class PrompterViewModel: ObservableObject {

    // MARK: User settings
    @Published var text: String = """
    This is a scrolling text test for NotchPrompter for macOS.
    The purpose of this demo is to check speed, readability, and smoothness. [pause]
    Adjust the font size, scroll speed, and window opacity to your preference.
    Keep your eyes on the notch and follow the moving line.

    Good morning everyone. [smile] Today I want to share a few key points about our upcoming product launch.
    First, we focused on reducing complexity and delivering a clean, intuitive user experience.
    Second, we significantly improved performance, ensuring that the application runs smoothly even under heavy load. [gesture to screen]
    Finally, we are excited to begin our rollout strategy and gather feedback from early adopters.
    Thank you for your time, and let's begin. [nod]

    You are capable of more than you think.
    Every step forward, no matter how small, builds momentum.
    Stay focused, stay consistent, and trust the process. [pause]
    Progress is progress, even if no one else sees it.
    Keep going — your future self will thank you.

    In the rapidly evolving world of technology, the ability to adapt and learn quickly has become more important than ever.
    Teams and individuals who embrace experimentation, curiosity, and continuous improvement tend to outperform those who rely on rigid structures and outdated processes.
    Innovation rarely comes from doing the same thing repeatedly. [emphasize] Instead, it thrives in environments where people feel safe to explore new ideas, challenge assumptions, and iterate rapidly.
    As we move into the next phase of development, our focus should remain on collaboration, communication, and execution.
    By aligning our goals and maintaining a clear vision, we can build products that not only solve real problems but also inspire and empower the people who use them.
    Let’s continue pushing boundaries and striving for excellence.
    """
    @Published var isPlaying: Bool = false
    @Published var offset: CGFloat = 0
    @Published var speed: Double = 12.0
    @Published var fontSize: Double = 10.0
    @Published var lineHeight: Double = 8.0
    @Published var pauseOnHover: Bool = true
    @Published var prompterWidth: CGFloat = 184
    @Published var prompterHeight: CGFloat = 150
    @Published var voiceActivation: Bool = false
    @Published var autoGain: Bool = false
    @Published var isPrompterVisible: Bool = true
    @Published var fontDesign: Font.Design = .monospaced
    @Published var selectedScreenIndex: Int = 0
    @Published var enableTopFade: Bool = true
    @Published var enableBottomFade: Bool = true
    @Published var topFadeHeight: Double = 40.0
    @Published var bottomFadeHeight: Double = 40.0
    @Published var showHoverControls: Bool = true
    @Published var hideFromScreenRecording: Bool = true
    @Published var prompterTheme: PrompterTheme = .dark
    @Published var horizontalAlignment: PrompterHorizontalAlignment = .center
    @Published var textAlignment: PrompterTextAlignment = .center
    @Published var showProgressBar: Bool = true
    @Published var enableGlobalKeyboardShortcuts: Bool = false
    @Published var speedIncrement: Double = 2.0
    @Published var manualScrollAmount: Double = 50.0

    var backScrollAmount: Double = 20.0 // pixels to scroll back


    private var timerCancellable: AnyCancellable?
    private var lastTick: CFTimeInterval?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Global keyboard shortcuts
    private var playPauseHotKey: HotKey?
    private var showHideHotKey: HotKey?
    private var increaseSpeedHotKey: HotKey?
    private var decreaseSpeedHotKey: HotKey?
    private var scrollUpHotKey: HotKey?
    private var scrollDownHotKey: HotKey?

    var audioMonitor: AudioMonitor?
    @Published var showMicrophoneAlert: Bool = false
    @Published var audioThreshold: Float = 0.01
    @Published var targetLevel: Double = 0.05  // default 5%


    // MARK: UserDefaults keys
    private enum Keys {
        static let text = "PrompterText"
        static let speed = "PrompterSpeed"
        static let fontSize = "PrompterFontSize"
        static let lineHeight = "PrompterLineHeight"
        static let pauseOnHover = "PrompterPauseOnHover"
        static let prompterWidth = "PrompterWidth"
        static let prompterHeight = "PrompterHeight"
        static let voiceActivation = "VoiceActivation"
        static let audioThreshold = "AudioThreshold"
        static let fontDesign = "FontDesign"
        static let selectedScreenIndex = "SelectedScreenIndex"
        static let opacity = "PrompterOpacity"
        static let enableTopFade = "EnableTopFade"
        static let enableBottomFade = "EnableBottomFade"
        static let topFadeHeight = "TopFadeHeight"
        static let bottomFadeHeight = "BottomFadeHeight"
        static let showHoverControls = "ShowHoverControls"
        static let hideFromScreenRecording = "HideFromScreenRecording"
        static let prompterTheme = "PrompterTheme"
        static let horizontalAlignment = "HorizontalAlignment"
        static let textAlignment = "TextAlignment"
        static let showProgressBar = "ShowProgressBar"
        static let enableGlobalKeyboardShortcuts = "EnableGlobalKeyboardShortcuts"
        static let speedIncrement = "SpeedIncrement"
        static let manualScrollAmount = "ManualScrollAmount"
    }

    // MARK: Init
    init() {
        loadSettings()
        observeSettingsChanges()
//        setupKeyboardShortcuts()
        $voiceActivation
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled {
                    self.requestMicrophoneAccessAndStart()
                } else {
                    self.audioMonitor?.stopMonitoring()
                }
            }
            .store(in: &cancellables)

        $enableGlobalKeyboardShortcuts
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled {
                    print("Global shortcuts enabled")
                    self.registerGlobalKeyboardShortcuts()
                } else {
                    print("Global shortcuts disabled")
                    self.unregisterGlobalKeyboardShortcuts()
                }
            }
            .store(in: &cancellables)
    }

    private func requestMicrophoneAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            monitorAudio()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.monitorAudio()

                    } else {
                        self?.voiceActivation = false
                        self?.showMicrophoneAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.voiceActivation = false
                self.showMicrophoneAlert = true
            }
        @unknown default:
            break
        }
    }


    func monitorAudio(){
        if(audioMonitor == nil){
            audioMonitor = AudioMonitor()
        }

        audioMonitor!.$rmsLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rmsLevel in
                guard let self = self else { return }
                let detected = rmsLevel > self.audioThreshold
//                print("Audio monitor - activation: \(detected) rms: \(rmsLevel) threshold: \(self.audioThreshold)")
                if detected {
                    self.lastTick = nil
                    self.isPlaying = true
                } else {
                    self.isPlaying = false
                }

            }
            .store(in: &cancellables)

        audioMonitor!.startMonitoring()
    }


    // MARK: Play/Pause
    func play() {
        lastTick = nil
        offset = 0
        isPlaying = true
    }

    func pause() {
        isPlaying = false
        offset = 0
    }

    func reset() {
        isPlaying = false
        lastTick = nil
    }

    func scrollBack() {
        offset = max(127, offset - backScrollAmount)
    }

    // MARK: Manual Scroll Control
    func scrollUp() {
        offset = max(127, offset - manualScrollAmount)
    }

    func scrollDown() {
        offset += manualScrollAmount
    }

    // MARK: Speed Control
    func increaseSpeed() {
        speed = min(40, speed + speedIncrement)
    }

    func decreaseSpeed() {
        speed = max(1, speed - speedIncrement)
    }

    // MARK: Keyboard Shortcuts Setup
    private func setupKeyboardShortcuts() {
        // Initial registration if enabled
        if enableGlobalKeyboardShortcuts {
            registerGlobalKeyboardShortcuts()
        }
    }

    private func registerGlobalKeyboardShortcuts() {

        print("Register hotkeys")
        // Control + Option + P: Play/Pause
        playPauseHotKey = HotKey(key: .p, modifiers: [.control, .option])
        playPauseHotKey?.keyDownHandler = { [weak self] in
            guard let self = self else { return }
            if !self.voiceActivation {
                if self.isPlaying {
                    self.pause()
                } else {
                    self.play()
                }
            }
        }

        // Control + Option + H: Show/Hide
        showHideHotKey = HotKey(key: .h, modifiers: [.control, .option])
        showHideHotKey?.keyDownHandler = { [weak self] in
            self?.isPrompterVisible.toggle()
        }

        // Control + Option + Right Arrow: Increase Speed
        increaseSpeedHotKey = HotKey(key: .rightArrow, modifiers: [.control, .option])
        increaseSpeedHotKey?.keyDownHandler = { [weak self] in
            self?.increaseSpeed()
        }

        // Control + Option + Left Arrow: Decrease Speed
        decreaseSpeedHotKey = HotKey(key: .leftArrow, modifiers: [.control, .option])
        decreaseSpeedHotKey?.keyDownHandler = { [weak self] in
            self?.decreaseSpeed()
        }

        // Control + Option + Up Arrow: Scroll Up
        scrollUpHotKey = HotKey(key: .upArrow, modifiers: [.control, .option])
        scrollUpHotKey?.keyDownHandler = { [weak self] in
            self?.scrollUp()
        }

        // Control + Option + Down Arrow: Scroll Down
        scrollDownHotKey = HotKey(key: .downArrow, modifiers: [.control, .option])
        scrollDownHotKey?.keyDownHandler = { [weak self] in
            self?.scrollDown()
        }
    }

    private func unregisterGlobalKeyboardShortcuts() {
        print("Unregister hotkeys")
        playPauseHotKey = nil
        showHideHotKey = nil
        increaseSpeedHotKey = nil
        decreaseSpeedHotKey = nil
        scrollUpHotKey = nil
        scrollDownHotKey = nil
    }

    private func tick(current: CFTimeInterval) {
        guard isPlaying else { return }

        let dt: CFTimeInterval
        if let last = lastTick {
            dt = current - last
        } else {
            dt = 0
        }
        lastTick = current

        offset += CGFloat(speed) * CGFloat(dt)
    }

    // MARK: Settings persistence
    private func observeSettingsChanges() {
        $text.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $speed.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $fontSize.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $lineHeight.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $pauseOnHover.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $prompterWidth.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $prompterHeight.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $voiceActivation.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $audioThreshold.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $fontDesign.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $selectedScreenIndex.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableTopFade.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableBottomFade.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $bottomFadeHeight.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $showHoverControls.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $hideFromScreenRecording.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $prompterTheme.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $horizontalAlignment.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $textAlignment.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $showProgressBar.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableGlobalKeyboardShortcuts.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $speedIncrement.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $manualScrollAmount.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        text = defaults.string(forKey: Keys.text) ?? text
        speed = defaults.double(forKey: Keys.speed)
        if speed == 0 { speed = 12.0 }
        fontSize = defaults.double(forKey: Keys.fontSize)
        if fontSize == 0 { fontSize = 12.0 }
        lineHeight = defaults.double(forKey: Keys.lineHeight)
        if lineHeight == 0 { lineHeight = 8.0 }
        pauseOnHover = defaults.object(forKey: Keys.pauseOnHover) as? Bool ?? true
        prompterWidth = CGFloat(defaults.double(forKey: Keys.prompterWidth))
        if prompterWidth == 0 { prompterWidth = 184 }
        prompterHeight = CGFloat(defaults.double(forKey: Keys.prompterHeight))
        if prompterHeight == 0 { prompterHeight = 150 }
        voiceActivation = defaults.object(forKey: Keys.voiceActivation) as? Bool ?? false
        let threshold = defaults.double(forKey: Keys.audioThreshold)
        audioThreshold = threshold == 0 ? 0.01 : Float(threshold)

        if let fontDesignRaw = defaults.string(forKey: Keys.fontDesign) {
            fontDesign = Font.Design(rawValue: fontDesignRaw) ?? .default
        }

        selectedScreenIndex = defaults.integer(forKey: Keys.selectedScreenIndex)

        enableTopFade = defaults.object(forKey: Keys.enableTopFade) as? Bool ?? true
        enableBottomFade = defaults.object(forKey: Keys.enableBottomFade) as? Bool ?? true
        topFadeHeight = defaults.double(forKey: Keys.topFadeHeight)
        if topFadeHeight == 0 { topFadeHeight = 40.0 }
        bottomFadeHeight = defaults.double(forKey: Keys.bottomFadeHeight)
        if bottomFadeHeight == 0 { bottomFadeHeight = 40.0 }
        showHoverControls = defaults.object(forKey: Keys.showHoverControls) as? Bool ?? true
        hideFromScreenRecording = defaults.object(forKey: Keys.hideFromScreenRecording) as? Bool ?? false

        if let themeRaw = defaults.string(forKey: Keys.prompterTheme) {
            prompterTheme = PrompterTheme(rawValue: themeRaw) ?? .dark
        }

        if let horizontalAlignRaw = defaults.string(forKey: Keys.horizontalAlignment) {
            horizontalAlignment = PrompterHorizontalAlignment(rawValue: horizontalAlignRaw) ?? .center
        }

        if let textAlignRaw = defaults.string(forKey: Keys.textAlignment) {
            textAlignment = PrompterTextAlignment(rawValue: textAlignRaw) ?? .center
        }

        showProgressBar = defaults.object(forKey: Keys.showProgressBar) as? Bool ?? true

        enableGlobalKeyboardShortcuts = defaults.object(forKey: Keys.enableGlobalKeyboardShortcuts) as? Bool ?? false
        speedIncrement = defaults.double(forKey: Keys.speedIncrement)
        if speedIncrement == 0 { speedIncrement = 2.0 }
        manualScrollAmount = defaults.double(forKey: Keys.manualScrollAmount)
        if manualScrollAmount == 0 { manualScrollAmount = 50.0 }
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(text, forKey: Keys.text)
        defaults.set(speed, forKey: Keys.speed)
        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(lineHeight, forKey: Keys.lineHeight)
        defaults.set(pauseOnHover, forKey: Keys.pauseOnHover)
        defaults.set(Double(prompterWidth), forKey: Keys.prompterWidth)
        defaults.set(Double(prompterHeight), forKey: Keys.prompterHeight)
        defaults.set(voiceActivation, forKey: Keys.voiceActivation)
        defaults.set(Double(audioThreshold), forKey: Keys.audioThreshold)
        defaults.set(fontDesign.rawValue, forKey: Keys.fontDesign)
        defaults.set(selectedScreenIndex, forKey: Keys.selectedScreenIndex)
        defaults.set(enableTopFade, forKey: Keys.enableTopFade)
        defaults.set(enableBottomFade, forKey: Keys.enableBottomFade)
        defaults.set(topFadeHeight, forKey: Keys.topFadeHeight)
        defaults.set(bottomFadeHeight, forKey: Keys.bottomFadeHeight)
        defaults.set(showHoverControls, forKey: Keys.showHoverControls)
        defaults.set(hideFromScreenRecording, forKey: Keys.hideFromScreenRecording)
        defaults.set(prompterTheme.rawValue, forKey: Keys.prompterTheme)
        defaults.set(horizontalAlignment.rawValue, forKey: Keys.horizontalAlignment)
        defaults.set(textAlignment.rawValue, forKey: Keys.textAlignment)
        defaults.set(showProgressBar, forKey: Keys.showProgressBar)
        defaults.set(enableGlobalKeyboardShortcuts, forKey: Keys.enableGlobalKeyboardShortcuts)
        defaults.set(speedIncrement, forKey: Keys.speedIncrement)
        defaults.set(manualScrollAmount, forKey: Keys.manualScrollAmount)
    }

    // MARK: Connector for display refresh
    private final class CADisplayLinkProxy {
        let subject = PassthroughSubject<CFTimeInterval, Never>()
        var link: CVDisplayLink?

        init() {
            var link: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)
            self.link = link
            if let l = link {
                CVDisplayLinkSetOutputCallback(l, { (_, _, _, _, _, userInfo) -> CVReturn in
                    let ref = Unmanaged<CADisplayLinkProxy>.fromOpaque(userInfo!).takeUnretainedValue()
                    let ts = CFAbsoluteTimeGetCurrent()
                    DispatchQueue.main.async {
                        ref.subject.send(ts)
                    }
                    return kCVReturnSuccess
                }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
                CVDisplayLinkStart(l)
            }
        }

        deinit {
            if let l = link {
                CVDisplayLinkStop(l)
            }
        }
    }

    private struct CADisplayLinkPublisher: Publisher {
        typealias Output = CFTimeInterval
        typealias Failure = Never

        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, CFTimeInterval == S.Input {
            let proxy = CADisplayLinkProxy()
            subscriber.receive(subscription: SubscriptionImpl(subscriber: subscriber, proxy: proxy))
        }

        private final class SubscriptionImpl<S: Subscriber>: Subscription where S.Input == CFTimeInterval, S.Failure == Never {
            private var subscriber: S?
            private var proxy: CADisplayLinkProxy?
            private var cancellables: Set<AnyCancellable> = []

            init(subscriber: S, proxy: CADisplayLinkProxy) {
                self.subscriber = subscriber
                self.proxy = proxy

                proxy.subject
                    .sink { [weak self] value in
                        _ = self?.subscriber?.receive(value)
                    }
                    .store(in: &cancellables)
            }

            func request(_ demand: Subscribers.Demand) {
                // demand not used
            }

            func cancel() {
                subscriber = nil
                proxy = nil
                cancellables.removeAll()
            }
        }
    }
}
// MARK: - Font.Design Extension for UserDefaults
extension Font.Design: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "default": self = .default
        case "serif": self = .serif
        case "rounded": self = .rounded
        case "monospaced": self = .monospaced
        default: return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .default: return "default"
        case .serif: return "serif"
        case .rounded: return "rounded"
        case .monospaced: return "monospaced"
        @unknown default: return "default"
        }
    }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        @unknown default: return "Default"
        }
    }

    var icon: String {
        switch self {
        case .default: return "Aa"
        case .serif: return "Aa"
        case .rounded: return "Aa"
        case .monospaced: return "Aa"
        @unknown default: return "Aa"
        }
    }

    var previewFont: Font {
        switch self {
        case .default: return .system(size: 20, weight: .medium, design: .default)
        case .serif: return .system(size: 20, weight: .medium, design: .serif)
        case .rounded: return .system(size: 20, weight: .medium, design: .rounded)
        case .monospaced: return .system(size: 20, weight: .medium, design: .monospaced)
        @unknown default: return .system(size: 20, weight: .medium, design: .default)
        }
    }
}

// MARK: - PrompterTheme Enum
enum PrompterTheme: String, CaseIterable {
    case dark = "dark"
    case light = "light"

    var displayName: LocalizedStringKey {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dark: return .black
        case .light: return .white
        }
    }

    var textColor: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        }
    }

    var fadeColor: Color {
        switch self {
        case .dark: return .black
        case .light: return .white
        }
    }
}

// MARK: - PrompterHorizontalAlignment Enum
enum PrompterHorizontalAlignment: String, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"

    var displayName: LocalizedStringKey {
        switch self {
        case .left: return "Left"
        case .center: return "Center"
        case .right: return "Right"
        }
    }

    var icon: String {
        switch self {
        case .left: return "arrow.left.to.line"
        case .center: return "arrow.left.and.right"
        case .right: return "arrow.right.to.line"
        }
    }
}
