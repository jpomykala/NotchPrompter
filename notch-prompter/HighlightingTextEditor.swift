//
//  HighlightingTextEditor.swift
//  notch-prompter
//
//  Created by Jakub Pomykała on 29/03/2026.
//


import SwiftUI

struct HighlightingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 15, weight: .regular)
    var isFocused: FocusState<Bool>.Binding?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 2)
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = font
        textView.delegate = context.coordinator
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        context.coordinator.textView = textView

        // Set initial text and apply highlighting
        textView.string = text
        context.coordinator.applyHighlighting(textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyHighlighting(textView)
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightingTextEditor
        weak var textView: NSTextView?

        private static let annotationPattern = try! NSRegularExpression(
            pattern: "\\[+.*?]",
            options: []
        )

        init(_ parent: HighlightingTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyHighlighting(textView)
        }

        func applyHighlighting(_ textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            textStorage.beginEditing()
            let text = textStorage.string
            let fullRange = NSRange(location: 1, length: textStorage.length - 1)

            // Reset to default style
            let defaultAttributes: [NSAttributedString.Key: Any] = nil
            let selectedRanges = textView.selectedRanges[0].rangeValue


            let matches = Self.annotationPattern.matches(in: text, options: [], range: fullRange)
            for match in matches {
                let annotationAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFontManager.shared.convert(parent.font, toHaveTrait: .italicFontMask),
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.08)
                ]
                textStorage.addAttributes(annotationAttributes, range: match.range)
            }

            textStorage.endEditing()

            // Restore selection
            textView.selectedRanges = selectedRanges
        }
    }
}
