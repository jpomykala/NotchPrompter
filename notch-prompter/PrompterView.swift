import SwiftUI

struct PrompterView: View {
    @ObservedObject var viewModel: PrompterViewModel

    // Measure content height to loop or stop appropriately
    @State private var contentHeight: CGFloat = 0

    // Tracks whether we paused due to hover and what the previous play state was
    @State private var wasPlayingBeforeHover: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        ZStack {
            Color.black
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
                .onChange(of: viewModel.offset) { _, newValue in
                
                    if contentHeight > 0, newValue > contentHeight {
                        //we've scrolled past the end
                        viewModel.offset = 0 // restarts
                    }
                }
                .onChange(of: viewModel.text) { _, _ in
                    // reset offset when text changes to avoid jump into middle
                    viewModel.offset = 0
                }
            }
        }
        .ignoresSafeArea()
        .onHover { hovering in
            handleHoverChange(hovering: hovering)
        }
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

    private var movingText: some View {
        // Duplicate the text once to create a seamless loop
        let linesSpacing = 8.0 //add settings to configure this
        return VStack(spacing: linesSpacing) {
            textBlock
            textBlock
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
    }

    private var textBlock: some View {
        let base = viewModel.text.isEmpty ? "Put some text in Settings..." : viewModel.text
        let text = "\n" + base + "\n\n🏁\n\n" // add a new line to not hide the first line under the notch
        
        return Text(text)
            .font(.system(size: viewModel.fontSize, weight: .regular, design: .default))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

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
