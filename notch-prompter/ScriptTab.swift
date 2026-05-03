import SwiftUI

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
