import SwiftUI
import AppKit
import HotKey

@main
struct NotchPrompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(viewModel: appDelegate.viewModel)
                .onAppear(perform: {
                    NSApp.setActivationPolicy(.regular)
                })
                .onDisappear(perform: {
                    NSApp.setActivationPolicy(.accessory)
                })
        }

        MenuBarExtra("NotchPrompter", systemImage: "text.justify") {
            MenuContent(viewModel: appDelegate.viewModel)
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

struct MenuContent: View {
    @ObservedObject var viewModel: PrompterViewModel
    

    
    var body: some View {
        Button {
            viewModel.isPrompterVisible.toggle()
        } label: {
            Label(viewModel.isPrompterVisible ? "Hide Prompter" : "Show Prompter",
                  systemImage: viewModel.isPrompterVisible ? "eye.slash" : "eye")
        }
        .keyboardShortcut("h", modifiers: [.command])
        
        Divider()
        
        Button {
            if viewModel.isPlaying {
                viewModel.pause()
            } else {
                viewModel.play()
            }
        }
        label: {
            Label(viewModel.isPlaying ? "Pause" : "Play",
                  systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
        }
        .disabled(viewModel.voiceActivation)
        .keyboardShortcut("p", modifiers: [.command])

        Button {
            viewModel.reset()
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
        }

        
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

//        Button("Sponsor the project") {
//            if let url = URL(string: "https://jpomykala.gumroad.com/l/notchprompter") {
//                NSWorkspace.shared.open(url)
//            }
//        }
        
        Divider()

        Button(role: .destructive) {
            NSApp.terminate(nil)
        } label: {
            Label("Exit", systemImage: "xmark.circle")
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
