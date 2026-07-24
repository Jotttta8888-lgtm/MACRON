import SwiftUI
import AppKit

class FocusTextField: NSTextField {
    var shouldAutoFocus = true
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if shouldAutoFocus {
            self.window?.makeFirstResponder(self)
            shouldAutoFocus = false
        }
    }
}

struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSTextField {
        let tf = FocusTextField()
        tf.placeholderString = placeholder
        tf.delegate = context.coordinator
        tf.bezelStyle = .roundedBezel
        tf.isEditable = true
        tf.isSelectable = true
        tf.isEnabled = true
        tf.allowsEditingTextAttributes = true
        tf.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        tf.stringValue = text
        return tf
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField
        
        init(_ parent: NativeTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit?()
                return true
            }
            return false
        }
    }
}
