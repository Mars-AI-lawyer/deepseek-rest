import AppKit

class MiMoBalanceViewController: NSViewController {

    private var balanceView: MiMoBalanceView {
        return view as! MiMoBalanceView
    }

    var onRefresh: (() -> Void)?
    var onLogin: (() -> Void)?

    override func loadView() {
        let v = MiMoBalanceView()
        v.onRefresh = { [weak self] in self?.onRefresh?() }
        v.onLogin = { [weak self] in self?.onLogin?() }
        view = v
        preferredContentSize = NSSize(width: 280, height: 220)
    }

    func showLoading() {
        balanceView.showLoading()
    }

    func update(with info: MiMoUsageInfo) {
        balanceView.update(with: info)
    }

    func showError(_ message: String) {
        balanceView.showError(message)
    }

    func showNoLogin() {
        balanceView.showNoLogin()
    }
}

class MiMoBalanceView: NSView {

    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField()
    private let planLabel = NSTextField()
    private let expireLabel = NSTextField()

    private let totalLabel = NSTextField()
    private let totalBar = ProgressBarView()
    private let totalValue = NSTextField()

    private let monthLabel = NSTextField()
    private let monthBar = ProgressBarView()
    private let monthValue = NSTextField()

    private let refreshButton = NSButton()
    private let loginButton = NSButton()

    private var stateLabel = NSTextField()
    private let tipLabel = NSTextField()

    var onRefresh: (() -> Void)?
    var onLogin: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Background
        effectView.material = .popover
        effectView.state = .active
        effectView.blendingMode = .behindWindow
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        // Title
        titleLabel.stringValue = "MiMo 套餐用量"
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Plan name (large)
        planLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        planLabel.textColor = .labelColor
        planLabel.alignment = .center
        planLabel.isEditable = false
        planLabel.isSelectable = false
        planLabel.isBordered = false
        planLabel.drawsBackground = false
        planLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(planLabel)

        // Expire date
        expireLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        expireLabel.textColor = .tertiaryLabelColor
        expireLabel.alignment = .center
        expireLabel.isEditable = false
        expireLabel.isSelectable = false
        expireLabel.isBordered = false
        expireLabel.drawsBackground = false
        expireLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(expireLabel)

        // State label (for loading/error)
        stateLabel.font = NSFont.systemFont(ofSize: 13)
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.alignment = .center
        stateLabel.isEditable = false
        stateLabel.isSelectable = false
        stateLabel.isBordered = false
        stateLabel.drawsBackground = false
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.isHidden = true
        addSubview(stateLabel)

        // Total row
        totalLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        totalLabel.textColor = .secondaryLabelColor
        totalLabel.isEditable = false
        totalLabel.isSelectable = false
        totalLabel.isBordered = false
        totalLabel.drawsBackground = false
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(totalLabel)

        totalBar.barColor = NSColor.systemBlue
        totalBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(totalBar)

        totalValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        totalValue.textColor = .labelColor
        totalValue.alignment = .right
        totalValue.isEditable = false
        totalValue.isSelectable = false
        totalValue.isBordered = false
        totalValue.drawsBackground = false
        totalValue.translatesAutoresizingMaskIntoConstraints = false
        addSubview(totalValue)

        // Month row
        monthLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        monthLabel.textColor = .secondaryLabelColor
        monthLabel.isEditable = false
        monthLabel.isSelectable = false
        monthLabel.isBordered = false
        monthLabel.drawsBackground = false
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(monthLabel)

        monthBar.barColor = NSColor.systemGreen
        monthBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(monthBar)

        monthValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        monthValue.textColor = .labelColor
        monthValue.alignment = .right
        monthValue.isEditable = false
        monthValue.isSelectable = false
        monthValue.isBordered = false
        monthValue.drawsBackground = false
        monthValue.translatesAutoresizingMaskIntoConstraints = false
        addSubview(monthValue)

        // Buttons
        refreshButton.title = "刷新"
        refreshButton.bezelStyle = .rounded
        refreshButton.controlSize = .small
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.target = self
        refreshButton.action = #selector(refreshTapped)
        addSubview(refreshButton)

        loginButton.title = "登录"
        loginButton.bezelStyle = .rounded
        loginButton.controlSize = .small
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.target = self
        loginButton.action = #selector(loginTapped)
        addSubview(loginButton)

        // Tip label
        tipLabel.stringValue = "⌥ 点击切换平台"
        tipLabel.font = NSFont.systemFont(ofSize: 10)
        tipLabel.textColor = .tertiaryLabelColor
        tipLabel.alignment = .center
        tipLabel.isEditable = false
        tipLabel.isSelectable = false
        tipLabel.isBordered = false
        tipLabel.drawsBackground = false
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tipLabel)

        // Layout
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            planLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            planLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            expireLabel.topAnchor.constraint(equalTo: planLabel.bottomAnchor, constant: 2),
            expireLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            stateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Total row
            totalLabel.topAnchor.constraint(equalTo: expireLabel.bottomAnchor, constant: 16),
            totalLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            totalLabel.widthAnchor.constraint(equalToConstant: 42),

            totalBar.centerYAnchor.constraint(equalTo: totalLabel.centerYAnchor),
            totalBar.leadingAnchor.constraint(equalTo: totalLabel.trailingAnchor, constant: 8),
            totalBar.heightAnchor.constraint(equalToConstant: 6),

            totalValue.centerYAnchor.constraint(equalTo: totalLabel.centerYAnchor),
            totalValue.leadingAnchor.constraint(equalTo: totalBar.trailingAnchor, constant: 8),
            totalValue.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            totalValue.widthAnchor.constraint(equalToConstant: 80),

            // Month row
            monthLabel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 10),
            monthLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            monthLabel.widthAnchor.constraint(equalToConstant: 42),

            monthBar.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            monthBar.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 8),
            monthBar.heightAnchor.constraint(equalToConstant: 6),

            monthValue.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            monthValue.leadingAnchor.constraint(equalTo: monthBar.trailingAnchor, constant: 8),
            monthValue.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            monthValue.widthAnchor.constraint(equalToConstant: 80),

            // Tip label
            tipLabel.topAnchor.constraint(equalTo: monthValue.bottomAnchor, constant: 12),
            tipLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            // Buttons
            refreshButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            refreshButton.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 6),

            loginButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            loginButton.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 6),
        ])

        showLoading()
    }

    func showLoading() {
        stateLabel.stringValue = "查询中..."
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.isHidden = false
        planLabel.isHidden = true
        expireLabel.isHidden = true
        totalLabel.isHidden = true
        totalBar.isHidden = true
        totalValue.isHidden = true
        monthLabel.isHidden = true
        monthBar.isHidden = true
        monthValue.isHidden = true
    }

    func update(with info: MiMoUsageInfo) {
        stateLabel.isHidden = true
        planLabel.isHidden = false
        expireLabel.isHidden = false
        totalLabel.isHidden = false
        totalBar.isHidden = false
        totalValue.isHidden = false
        monthLabel.isHidden = false
        monthBar.isHidden = false
        monthValue.isHidden = false

        // 套餐名称
        planLabel.stringValue = "MiMo \(info.planName)"

        // 到期时间
        let expireText = info.expired ? "已过期" : "到期: \(formatDate(info.expireDate))"
        expireLabel.stringValue = expireText
        expireLabel.textColor = info.expired ? .systemRed : .tertiaryLabelColor

        // 总用量
        totalValue.stringValue = "\(info.totalUsedFormatted) / \(info.totalLimitFormatted)"
        totalBar.progress = CGFloat(min(info.usagePercent, 1.0))

        // 月度用量
        let monthPercent = info.monthLimit > 0 ? Double(info.monthUsed) / Double(info.monthLimit) : 0
        monthValue.stringValue = "\(info.monthUsedFormatted) / \(info.monthLimitFormatted)"
        monthBar.progress = CGFloat(min(monthPercent, 1.0))
    }

    func showError(_ message: String) {
        stateLabel.stringValue = message
        stateLabel.textColor = .systemRed
        stateLabel.isHidden = false
        planLabel.isHidden = true
        expireLabel.isHidden = true
        totalLabel.isHidden = true
        totalBar.isHidden = true
        totalValue.isHidden = true
        monthLabel.isHidden = true
        monthBar.isHidden = true
        monthValue.isHidden = true
    }

    func showNoLogin() {
        stateLabel.stringValue = "未登录\n点击登录"
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.isHidden = false
        planLabel.isHidden = true
        expireLabel.isHidden = true
        totalLabel.isHidden = true
        totalBar.isHidden = true
        totalValue.isHidden = true
        monthLabel.isHidden = true
        monthBar.isHidden = true
        monthValue.isHidden = true
    }

    @objc private func refreshTapped() {
        onRefresh?()
    }

    @objc private func loginTapped() {
        onLogin?()
    }

    private func formatDate(_ dateString: String) -> String {
        // 输入格式: "2026-05-29 23:59:59"
        let parts = dateString.split(separator: " ")
        if let datePart = parts.first {
            return String(datePart)
        }
        return dateString
    }
}
