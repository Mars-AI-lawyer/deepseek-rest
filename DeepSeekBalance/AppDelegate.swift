import AppKit

enum Platform {
    case deepseek
    case mimo
}

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover!
    private var balanceVC: BalanceViewController!
    private var token: String?
    private var cachedBalance: BalanceInfo?
    private var hideTimer: Timer?

    // MiMo 相关
    private var mimoPopover: NSPopover!
    private var mimoBalanceVC: MiMoBalanceViewController!
    private var cachedMiMoUsage: MiMoUsageInfo?
    private var loginWindowController: MiMoLoginWindowController?

    // 当前平台
    private var currentPlatform: Platform = .deepseek

    func applicationDidFinishLaunching(_ notification: Notification) {
        initPopover()
        setupStatusItem()
        attemptAutoRefresh()
    }

    // MARK: - Popover

    private func initPopover() {
        // DeepSeek Popover
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

        // MiMo Popover
        mimoBalanceVC = MiMoBalanceViewController()
        mimoBalanceVC.onRefresh = { [weak self] in
            self?.mimoBalanceVC.showLoading()
            self?.showPopover()
            self?.fetchMiMoUsage()
        }
        mimoBalanceVC.onLogin = { [weak self] in
            self?.mimoPopover.close()
            self?.showMiMoLogin()
        }

        mimoPopover = NSPopover()
        mimoPopover.contentViewController = mimoBalanceVC
        mimoPopover.behavior = .transient
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

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: button.bounds, options: options, owner: self, userInfo: nil)
        button.addTrackingArea(trackingArea)
    }

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()

        // 平台切换
        let platformItem = NSMenuItem(title: "当前: \(currentPlatform == .deepseek ? "DeepSeek" : "MiMo")", action: nil, keyEquivalent: "")
        platformItem.isEnabled = false
        menu.addItem(platformItem)

        menu.addItem(NSMenuItem.separator())

        if currentPlatform == .deepseek {
            let switchItem = NSMenuItem(title: "切换到 MiMo", action: #selector(switchToMiMo), keyEquivalent: "m")
            switchItem.target = self
            menu.addItem(switchItem)
        } else {
            let switchItem = NSMenuItem(title: "切换到 DeepSeek", action: #selector(switchToDeepSeek), keyEquivalent: "d")
            switchItem.target = self
            menu.addItem(switchItem)
        }

        menu.addItem(NSMenuItem.separator())

        if currentPlatform == .mimo {
            let loginItem = NSMenuItem(title: "MiMo 登录", action: #selector(showMiMoLoginMenu), keyEquivalent: "l")
            loginItem.target = self
            menu.addItem(loginItem)
        }

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
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
        if currentPlatform == .deepseek {
            token = KeychainManager.load()
            if token == nil {
                DispatchQueue.main.async { self.showTokenPrompt() }
            } else {
                fetchBalance()
            }
        } else {
            if MiMoAPI.loadCookies() == nil {
                DispatchQueue.main.async { self.showMiMoLogin() }
            } else {
                fetchMiMoUsage()
            }
        }
    }

    // MARK: - Mouse Tracking (hover)

    @objc(mouseEntered:) func mouseEntered(with event: NSEvent) {
        hideTimer?.invalidate()
        hideTimer = nil

        if currentPlatform == .deepseek {
            if let cached = cachedBalance {
                balanceVC.update(with: cached)
            } else if token != nil {
                balanceVC.showLoading()
            } else {
                balanceVC.showNoToken()
            }
        } else {
            if let cached = cachedMiMoUsage {
                mimoBalanceVC.update(with: cached)
            } else if MiMoAPI.loadCookies() != nil {
                mimoBalanceVC.showLoading()
            } else {
                mimoBalanceVC.showNoLogin()
            }
        }
        showPopover()

        if currentPlatform == .deepseek && token != nil {
            fetchBalance()
        } else if currentPlatform == .mimo && MiMoAPI.loadCookies() != nil {
            fetchMiMoUsage()
        }
    }

    @objc(mouseExited:) func mouseExited(with event: NSEvent) {
        scheduleHide()
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }

        if currentPlatform == .deepseek {
            guard !popover.isShown else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        } else {
            guard !mimoPopover.isShown else { return }
            mimoPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.currentPlatform == .deepseek {
                self.popover.close()
            } else {
                self.mimoPopover.close()
            }
        }
    }

    // MARK: - Click

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        // 检测 Option 键点击
        if event.modifierFlags.contains(.option) {
            showPlatformMenu()
            return
        }

        if currentPlatform == .deepseek {
            guard token != nil else {
                showTokenPrompt()
                return
            }
            balanceVC.showLoading()
            showPopover()
            fetchBalance()
        } else {
            guard MiMoAPI.loadCookies() != nil else {
                mimoBalanceVC.showNoLogin()
                showPopover()
                return
            }
            mimoBalanceVC.showLoading()
            showPopover()
            fetchMiMoUsage()
        }
    }

    private func showPlatformMenu() {
        let menu = buildContextMenu()

        // 在状态栏图标下方显示菜单
        if let button = statusItem?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
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

    // MARK: - MiMo

    private func fetchMiMoUsage() {
        MiMoAPI.fetchUsage { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let info):
                    self?.cachedMiMoUsage = info
                    self?.mimoBalanceVC.update(with: info)
                case .failure(let error):
                    if case .unauthorized = error {
                        MiMoAPI.deleteCookies()
                        self?.cachedMiMoUsage = nil
                        self?.mimoBalanceVC.showNoLogin()
                    } else {
                        self?.mimoBalanceVC.showError(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func showMiMoLogin() {
        loginWindowController = MiMoLoginWindowController()
        loginWindowController?.onLoginSuccess = { [weak self] cookieString in
            MiMoAPI.saveCookies(cookieString)
            self?.cachedMiMoUsage = nil
            self?.mimoBalanceVC.showLoading()
            self?.showPopover()
            self?.fetchMiMoUsage()
            self?.loginWindowController = nil
        }
        loginWindowController?.onLoginCancel = { [weak self] in
            self?.loginWindowController = nil
        }
        loginWindowController?.showWindow(nil)
        loginWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func switchToMiMo() {
        currentPlatform = .mimo
        popover.close()
        updateStatusIcon()
        attemptAutoRefresh()
    }

    @objc private func switchToDeepSeek() {
        currentPlatform = .deepseek
        mimoPopover.close()
        updateStatusIcon()
        attemptAutoRefresh()
    }

    @objc private func showMiMoLoginMenu() {
        showMiMoLogin()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        if currentPlatform == .deepseek {
            button.image = loadStatusIcon()
        } else {
            button.image = loadMiMoStatusIcon()
        }
    }

    private func loadMiMoStatusIcon() -> NSImage? {
        // 尝试加载自定义图标，否则使用系统图标
        let names = ["mimo_icon@2x", "mimo_icon"]
        for name in names {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let img = NSImage(contentsOfFile: path) {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                return img
            }
        }
        let img = NSImage(systemSymbolName: "cpu",
                          accessibilityDescription: "MiMo")
        img?.isTemplate = true
        return img
    }
}
