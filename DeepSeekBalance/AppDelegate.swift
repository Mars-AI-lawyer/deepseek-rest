import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover!
    private var balanceVC: BalanceViewController!
    private var token: String?
    private var cachedBalance: BalanceInfo?
    private var hideTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        initPopover()
        setupStatusItem()
        attemptAutoRefresh()
    }

    // MARK: - Popover

    private func initPopover() {
        balanceVC = BalanceViewController()
        balanceVC.onRefresh = { [weak self] in
            self?.balanceVC.showLoading()
            self?.showPopover()
            self?.fetchBalance()
        }
        balanceVC.onChangeToken = { [weak self] in
            self?.popover.close()
            self?.showTokenPrompt()
        }

        popover = NSPopover()
        popover.contentViewController = balanceVC
        popover.behavior = .transient
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        button.image = loadStatusIcon()
        button.image?.isTemplate = true
        button.focusRingType = .none
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: button.bounds, options: options, owner: self, userInfo: nil)
        button.addTrackingArea(trackingArea)
    }

    private func loadStatusIcon() -> NSImage? {
        let names = ["status_icon@2x", "status_icon"]
        for name in names {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let img = NSImage(contentsOfFile: path) {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                return img
            }
        }
        let img = NSImage(systemSymbolName: "dollarsign.circle",
                          accessibilityDescription: "DeepSeek")
        img?.isTemplate = true
        return img
    }

    private func attemptAutoRefresh() {
        token = KeychainManager.load()
        if token == nil {
            DispatchQueue.main.async { self.showTokenPrompt() }
        } else {
            fetchBalance()
        }
    }

    // MARK: - Mouse Tracking (hover)

    @objc(mouseEntered:) func mouseEntered(with event: NSEvent) {
        hideTimer?.invalidate()
        hideTimer = nil

        if let cached = cachedBalance {
            balanceVC.update(with: cached)
        } else if token != nil {
            balanceVC.showLoading()
        } else {
            balanceVC.showNoToken()
        }
        showPopover()

        if token != nil {
            fetchBalance()
        }
    }

    @objc(mouseExited:) func mouseExited(with event: NSEvent) {
        scheduleHide()
    }

    private func showPopover() {
        guard let button = statusItem?.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.popover.close()
        }
    }

    // MARK: - Click

    @objc private func statusItemClicked() {
        guard token != nil else {
            showTokenPrompt()
            return
        }
        balanceVC.showLoading()
        showPopover()
        fetchBalance()
    }

    // MARK: - Network

    private func fetchBalance() {
        guard let token = token else { return }

        DeepSeekAPI.fetchBalance(token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let info):
                    self?.cachedBalance = info
                    self?.balanceVC.update(with: info)
                case .failure(let error):
                    if case .unauthorized = error {
                        KeychainManager.delete()
                        self?.token = nil
                        self?.cachedBalance = nil
                        self?.balanceVC.showNoToken()
                        self?.popover.close()
                        self?.showTokenPrompt()
                    } else {
                        self?.balanceVC.showError(error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Token Prompt

    private func showTokenPrompt() {
        TokenPromptController.show { [weak self] newToken in
            guard let tk = newToken, !tk.isEmpty else { return }
            KeychainManager.save(tk)
            self?.token = tk
            self?.cachedBalance = nil
            self?.balanceVC.showLoading()
            self?.showPopover()
            self?.fetchBalance()
        }
    }
}
