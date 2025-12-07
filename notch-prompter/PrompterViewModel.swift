import Foundation
import Combine
import CoreVideo
import AVFoundation
import Accelerate

final class PrompterViewModel: ObservableObject {
    
    // MARK: User settings
    @Published var text: String = """
    This is a scrolling text test for NotchPrompter for macOS.
    The purpose of this demo is to check speed, readability, and smoothness.  
    Adjust the font size, scroll speed, and window opacity to your preference.  
    Keep your eyes on the notch and follow the moving line.

    Good morning everyone. Today I want to share a few key points about our upcoming product launch.
    First, we focused on reducing complexity and delivering a clean, intuitive user experience.
    Second, we significantly improved performance, ensuring that the application runs smoothly even under heavy load.
    Finally, we are excited to begin our rollout strategy and gather feedback from early adopters.
    Thank you for your time, and let's begin.

    You are capable of more than you think.  
    Every step forward, no matter how small, builds momentum.  
    Stay focused, stay consistent, and trust the process.  
    Progress is progress, even if no one else sees it.  
    Keep going — your future self will thank you.
    
    In the rapidly evolving world of technology, the ability to adapt and learn quickly has become more important than ever.
    Teams and individuals who embrace experimentation, curiosity, and continuous improvement tend to outperform those who rely on rigid structures and outdated processes.
    Innovation rarely comes from doing the same thing repeatedly. Instead, it thrives in environments where people feel safe to explore new ideas, challenge assumptions, and iterate rapidly.
    As we move into the next phase of development, our focus should remain on collaboration, communication, and execution.
    By aligning our goals and maintaining a clear vision, we can build products that not only solve real problems but also inspire and empower the people who use them.
    Let’s continue pushing boundaries and striving for excellence.
    """
    @Published var isPlaying: Bool = false
    @Published var offset: CGFloat = 0
    @Published var speed: Double = 12.0
    @Published var fontSize: Double = 10.0
    @Published var pauseOnHover: Bool = true
    @Published var prompterWidth: CGFloat = 184
    @Published var prompterHeight: CGFloat = 150
    @Published var voiceActivation: Bool = false
    @Published var autoGain: Bool = true
    
    
    private var timerCancellable: AnyCancellable?
    private var lastTick: CFTimeInterval?
    private var cancellables: Set<AnyCancellable> = []
    
    var audioMonitor: AudioMonitor?
    @Published var showMicrophoneAlert: Bool = false
    @Published var audioThreshold: Float = 0.01
    @Published var targetLevel: Double = 0.05  // default 5%

    
    // MARK: UserDefaults keys
    private enum Keys {
        static let text = "PrompterText"
        static let speed = "PrompterSpeed"
        static let fontSize = "PrompterFontSize"
        static let pauseOnHover = "PrompterPauseOnHover"
        static let prompterWidth = "PrompterWidth"
        static let prompterHeight = "PrompterHeight"
        static let voiceActivation = "VoiceActivation"
        static let audioThreshold = "AudioThreshold"
    }
    
    // MARK: Init
    init() {
        loadSettings()
        startTimer()
        observeSettingsChanges()
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
                print("Audio monitor - activation: \(detected) rms: \(rmsLevel) threshold: \(self.audioThreshold)")
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

//
//    func updateGainIfNeeded() {
//        guard autoGain else { return }
//        guard let monitor = audioMonitor else { return }
//        
//        let rms = monitor.rmsLevel
//        let diff = targetLevel - rms
//        
//        // mała korekta gain (smooth)
//        monitor.gain += Float(diff * 2.0)
//        
//        monitor.gain = max(0.1, min(monitor.gain, 10.0)) // clamp
//    }

    
    // MARK: Play/Pause
    func play() {
        lastTick = nil
        isPlaying = true
    }
    
    func pause() {
        isPlaying = false
    }
    
    func reset() {
        isPlaying = false
        offset = 0
        lastTick = nil
    }
    
    // MARK: Timer
    private func startTimer() {
        timerCancellable = CADisplayLinkPublisher()
            .sink { [weak self] timestamp in
                self?.tick(current: timestamp)
            }
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
        $pauseOnHover.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $prompterWidth.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $prompterHeight.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $voiceActivation.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $audioThreshold.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        text = defaults.string(forKey: Keys.text) ?? text
        speed = defaults.double(forKey: Keys.speed)
        if speed == 0 { speed = 12.0 }
        fontSize = defaults.double(forKey: Keys.fontSize)
        if fontSize == 0 { fontSize = 12.0 }
        pauseOnHover = defaults.object(forKey: Keys.pauseOnHover) as? Bool ?? true
        prompterWidth = CGFloat(defaults.double(forKey: Keys.prompterWidth))
        if prompterWidth == 0 { prompterWidth = 184 }
        prompterHeight = CGFloat(defaults.double(forKey: Keys.prompterHeight))
        if prompterHeight == 0 { prompterHeight = 150 }
        voiceActivation = defaults.object(forKey: Keys.voiceActivation) as? Bool ?? false
        let threshold = defaults.double(forKey: Keys.audioThreshold)
        audioThreshold = threshold == 0 ? 0.01 : Float(threshold)
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(text, forKey: Keys.text)
        defaults.set(speed, forKey: Keys.speed)
        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(pauseOnHover, forKey: Keys.pauseOnHover)
        defaults.set(Double(prompterWidth), forKey: Keys.prompterWidth)
        defaults.set(Double(prompterHeight), forKey: Keys.prompterHeight)
        defaults.set(voiceActivation, forKey: Keys.voiceActivation)
        defaults.set(Double(audioThreshold), forKey: Keys.audioThreshold)
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
                    ref.subject.send(ts)
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
