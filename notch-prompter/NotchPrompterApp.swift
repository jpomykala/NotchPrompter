import SwiftUI
import AppKit

@main
struct NotchPrompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(viewModel: appDelegate.viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }

        MenuBarExtra("NotchPrompter", systemImage: "text.justify") {
            Button {
                appDelegate.viewModel.initialPlay()
            }
            label: {
                Label("Play", systemImage: "play.fill")
            }.disabled(appDelegate.viewModel.isPlaying) 

            Button {
                appDelegate.viewModel.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            };

            
            Button {
                appDelegate.viewModel.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            };

            
            Divider()

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Feedback") {
                if let url = URL(string: "https://github.com/jpomykala/NotchPrompter/issues") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Donate") {
                if let url = URL(string: "https://github.com/sponsors/jpomykala") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Exit", systemImage: "xmark.circle")
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = PrompterViewModel()
    private var prompterWindow: PrompterWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        prompterWindow = PrompterWindow(viewModel: viewModel)
        prompterWindow.show()
        NSApp.setActivationPolicy(.accessory)
    }
}
