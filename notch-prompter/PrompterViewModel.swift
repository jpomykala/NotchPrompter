import Foundation
import Combine
import CoreVideo
import AVFoundation
import Accelerate

final class PrompterViewModel: ObservableObject {
    // MARK: User settings
    @Published var text: String = """
    This is a sample text for your prompter
    You can add your own text in Settings
    
    Here is a sample text:
    Et aliquip et aute duis. Et aute duis voluptate. Duis voluptate eiusmod elit amet excepteur non. Eiusmod elit amet excepteur, non. Excepteur non ex veniam aliquip enim irure. Ex veniam, aliquip enim irure nulla aliquip.
    
    Aliquip et aute duis, voluptate eiusmod elit amet. Duis voluptate eiusmod elit amet excepteur non. Eiusmod elit amet excepteur, non. Excepteur non ex veniam aliquip enim irure. Ex veniam, aliquip enim irure nulla aliquip. Enim irure nulla aliquip est et irure, elit. Aliquip est et, irure. Irure elit lorem proident, excepteur. Proident excepteur et ad nulla nulla cillum et. Et, ad nulla nulla.
    
    Et aute duis voluptate. Duis voluptate eiusmod elit amet excepteur non. Eiusmod elit amet excepteur, non. Excepteur non ex veniam aliquip enim irure. Ex veniam, aliquip enim irure nulla aliquip.
    
    Aute duis voluptate, eiusmod elit amet excepteur. Eiusmod elit amet excepteur, non. Excepteur non ex veniam aliquip enim irure. Ex veniam, aliquip enim irure nulla aliquip. Enim irure nulla aliquip est et irure, elit. Aliquip est et, irure. Irure elit lorem proident, excepteur. Proident excepteur et ad nulla nulla cillum et.
    """
    @Published var isPlaying: Bool = false
    @Published var offset: CGFloat = 0
    @Published var speed: Double = 12.0
    @Published var fontSize: Double = 14.0
    @Published var pauseOnHover: Bool = true
    @Published var prompterWidth: CGFloat = 400
    @Published var prompterHeight: CGFloat = 150
    
    private var timerCancellable: AnyCancellable?
    private var lastTick: CFTimeInterval?
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: UserDefaults keys
    private enum Keys {
        static let text = "PrompterText"
        static let speed = "PrompterSpeed"
        static let fontSize = "PrompterFontSize"
        static let pauseOnHover = "PrompterPauseOnHover"
        static let prompterWidth = "PrompterWidth"
        static let prompterHeight = "PrompterHeight"
    }
    
    // MARK: Init
    init() {
        loadSettings()
        startTimer()
        observeSettingsChanges()
    }
    
    // MARK: Play/Pause
    func initialPlay() {
        lastTick = nil
        offset -= speed // magic number to avoid text jumping
        isPlaying = true
    }
    
    func playNoOffsetChange() {
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
            .receive(on: RunLoop.main)
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
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        text = defaults.string(forKey: Keys.text) ?? text
        speed = defaults.double(forKey: Keys.speed)
        if speed == 0 { speed = 12.0 }
        fontSize = defaults.double(forKey: Keys.fontSize)
        if fontSize == 0 { fontSize = 14.0 }
        pauseOnHover = defaults.object(forKey: Keys.pauseOnHover) as? Bool ?? true
        prompterWidth = CGFloat(defaults.double(forKey: Keys.prompterWidth))
        if prompterWidth == 0 { prompterWidth = 400 }
        prompterHeight = CGFloat(defaults.double(forKey: Keys.prompterHeight))
        if prompterHeight == 0 { prompterHeight = 150 }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(text, forKey: Keys.text)
        defaults.set(speed, forKey: Keys.speed)
        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(pauseOnHover, forKey: Keys.pauseOnHover)
        defaults.set(Double(prompterWidth), forKey: Keys.prompterWidth)
        defaults.set(Double(prompterHeight), forKey: Keys.prompterHeight)
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
