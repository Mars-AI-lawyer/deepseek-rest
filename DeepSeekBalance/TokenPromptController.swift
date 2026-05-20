import AppKit

class TokenPromptController {

    static func show(onSave: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "输入 DeepSeek API Token"
        alert.informativeText = "请输入您的 DeepSeek Bearer Token，用于查询账户余额。"
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "Token")

        let inputField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
        inputField.isBezeled = true
        inputField.bezelStyle = .roundedBezel

        if let existing = KeychainManager.load() {
            inputField.stringValue = existing
        }

        alert.accessoryView = inputField
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")
        alert.window.initialFirstResponder = inputField

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let token = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            onSave(token.isEmpty ? nil : token)
        } else {
            onSave(nil)
        }
    }
}
