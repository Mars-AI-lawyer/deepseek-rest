import AppKit

enum AppState {
    case noToken
    case loading
    case loaded(BalanceInfo)
    case error(String)
}

struct MenuBuilder {

    static func build(menu: NSMenu,
                      state: AppState,
                      changeTokenAction: Selector,
                      refreshAction: Selector,
                      quitAction: Selector,
                      target: AnyObject) {

        menu.removeAllItems()

        switch state {
        case .noToken:
            addHeader(menu: menu, title: "DeepSeek 余额")
            addSeparator(menu: menu)
            addItem(menu: menu, title: "未设置 API Token", enabled: false)
            addSeparator(menu: menu)
            addItem(menu: menu, title: "设置 Token", enabled: true, target: target, action: changeTokenAction)
            addItem(menu: menu, title: "退出", enabled: true, target: target, action: quitAction)

        case .loading:
            addHeader(menu: menu, title: "DeepSeek 余额")
            addSeparator(menu: menu)
            addItem(menu: menu, title: "查询中...", enabled: false)
            addSeparator(menu: menu)
            addItem(menu: menu, title: "退出", enabled: true, target: target, action: quitAction)

        case .loaded(let info):
            addHeader(menu: menu, title: "DeepSeek 余额")
            addSeparator(menu: menu)

            let totalStr = formatBalance(info.totalBalance, currency: info.currency)
            let grantedStr = formatBalance(info.grantedBalance, currency: info.currency)
            let toppedUpStr = formatBalance(info.toppedUpBalance, currency: info.currency)

            addItem(menu: menu, title: "总余额    \(totalStr)", enabled: false)
            addItem(menu: menu, title: "赠送余额  \(grantedStr)", enabled: false)
            addItem(menu: menu, title: "充值余额  \(toppedUpStr)", enabled: false)

            addSeparator(menu: menu)
            addItem(menu: menu, title: "刷新", keyEquivalent: "r", target: target, action: refreshAction)
            addItem(menu: menu, title: "修改 Token", enabled: true, target: target, action: changeTokenAction)
            addSeparator(menu: menu)
            addItem(menu: menu, title: "退出", enabled: true, target: target, action: quitAction)

        case .error(let message):
            addHeader(menu: menu, title: "DeepSeek 余额")
            addSeparator(menu: menu)
            addItem(menu: menu, title: "查询失败", enabled: false)
            addItem(menu: menu, title: message, enabled: false)
            addSeparator(menu: menu)
            addItem(menu: menu, title: "重试", target: target, action: refreshAction)
            addItem(menu: menu, title: "修改 Token", enabled: true, target: target, action: changeTokenAction)
            addSeparator(menu: menu)
            addItem(menu: menu, title: "退出", enabled: true, target: target, action: quitAction)
        }
    }

    // MARK: - Helpers

    private static func addHeader(menu: NSMenu, title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        let font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font]
        )
        menu.addItem(item)
    }

    private static func addSeparator(menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
    }

    private static func addItem(menu: NSMenu,
                                title: String,
                                enabled: Bool = true,
                                keyEquivalent: String = "",
                                target: AnyObject? = nil,
                                action: Selector? = nil) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.isEnabled = enabled
        item.target = target
        menu.addItem(item)
    }

    private static func formatBalance(_ amount: String, currency: String) -> String {
        guard let value = Double(amount) else {
            return "\(amount) \(currency)"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let formatted = formatter.string(from: NSNumber(value: value)) {
            return "\(formatted) \(currency)"
        }
        return "\(amount) \(currency)"
    }
}
