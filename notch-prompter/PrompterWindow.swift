import AppKit
import SwiftUI
import Combine

final class PrompterWindow {
    private var window: NSWindow!
    private let viewModel: PrompterViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: PrompterViewModel) {
        self.viewModel = viewModel

        let contentView = PrompterView(viewModel: viewModel)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 16,
                topTrailingRadius: 0
            )).border(Color.black.opacity(0.0), width: 0)

        let hosting = NSHostingView(rootView: contentView)
        hosting.wantsLayer = true
        hosting.layer?.masksToBounds = true

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0,
                                width: viewModel.prompterWidth,
                                height: viewModel.prompterHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = false // true adds a little cool effect, but it's not needed for "Notch" type app
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.contentView = hosting

        viewModel.$prompterWidth
            .combineLatest(viewModel.$prompterHeight)
            .receive(on: RunLoop.main)
            .sink { [weak self] width, height in
                self?.resizeWindow(width: width, height: height)
            }
            .store(in: &cancellables)
    }

    func show() {
        guard let screen = NSScreen.main else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            return
        }

        let frame = topCenterFrame(width: viewModel.prompterWidth, height: viewModel.prompterHeight, screen: screen)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func resizeWindow(width: CGFloat, height: CGFloat) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let frame = topCenterFrame(width: width, height: height, screen: screen)

        window.setFrame(frame, display: true, animate: true)
    }

    private func topCenterFrame(width: CGFloat, height: CGFloat, screen: NSScreen) -> CGRect {
        let x = screen.frame.midX - width / 2
        let heightOfBorderTopWithRadiusToHide: CGFloat = 4
        let y = screen.frame.maxY - height + heightOfBorderTopWithRadiusToHide// slight offset to hide border under notch
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
