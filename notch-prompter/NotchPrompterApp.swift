import SwiftUI
import AppKit

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

        MenuBarExtra {
            MenuContent(viewModel: appDelegate.viewModel)
        } label: {
            let image: NSImage = {
                $0.size.height = 12
                $0.size.width = 12
                return $0
            }(NSImage(named: "MenuBarIcon")!)

            Image(nsImage: image)
                .renderingMode(.template)
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
        .keyboardShortcut("h", modifiers: [.command, .option])

        Divider()

        Button("Play") {
               viewModel.play()
        }

        .disabled(viewModel.voiceActivation)
        .keyboardShortcut("p", modifiers: [.command, .option])

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
            if let url = URL(string: "mailto:jakub@jpomykala.com?subject=NotchPrompter%20feedback") {
                NSWorkspace.shared.open(url)
            }
        }

        Button("Project page") {
            if let url = URL(string: "https://notchprompter.com") {
                NSWorkspace.shared.open(url)
            }
        }

       Button("Help translate") {
           if let url = URL(string: "https://simplelocalize.io/suggestions/?id=f1f11f9305dc44a2872b6a154dea6edc") {
               NSWorkspace.shared.open(url)
           }
       }
        Button("Sponsor the project") {
            if let url = URL(string: "https://jpomykala.gumroad.com/l/notchprompter") {
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
}
