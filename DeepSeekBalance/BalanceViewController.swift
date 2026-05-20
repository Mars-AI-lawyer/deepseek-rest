import AppKit

class BalanceViewController: NSViewController {

    private var balanceView: BalancePopoverView {
        return view as! BalancePopoverView
    }

    var onRefresh: (() -> Void)?
    var onChangeToken: (() -> Void)?

    override func loadView() {
        let v = BalancePopoverView()
        v.onRefresh = { [weak self] in self?.onRefresh?() }
        v.onChangeToken = { [weak self] in self?.onChangeToken?() }
        view = v
        preferredContentSize = NSSize(width: 280, height: 180)
    }

    func showLoading() {
        balanceView.showLoading()
    }

    func update(with info: BalanceInfo) {
        balanceView.update(with: info)
    }

    func showError(_ message: String) {
        balanceView.showError(message)
    }

    func showNoToken() {
        balanceView.showNoToken()
    }
}

class BalancePopoverView: NSView {

    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "DeepSeek 余额")
    private let balanceLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "总余额")

    private let toppedUpLabel = NSTextField(labelWithString: "充值余额")
    private let toppedUpBar = ProgressBarView()
    private let toppedUpValue = NSTextField(labelWithString: "")

    private let grantedLabel = NSTextField(labelWithString: "赠送余额")
    private let grantedBar = ProgressBarView()
    private let grantedValue = NSTextField(labelWithString: "")

    private let refreshButton = NSButton()
    private let settingsButton = NSButton()

    private var stateLabel = NSTextField(labelWithString: "")

    var onRefresh: (() -> Void)?
    var onChangeToken: (() -> Void)?

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
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Balance (large number)
        balanceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        balanceLabel.textColor = .labelColor
        balanceLabel.alignment = .center
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(balanceLabel)

        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .tertiaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        // State label (for loading/error)
        stateLabel.font = NSFont.systemFont(ofSize: 13)
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.alignment = .center
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.isHidden = true
        addSubview(stateLabel)

        // Topped up row
        toppedUpLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        toppedUpLabel.textColor = .secondaryLabelColor
        toppedUpLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpLabel)

        toppedUpBar.barColor = NSColor.systemBlue
        toppedUpBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpBar)

        toppedUpValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        toppedUpValue.textColor = .labelColor
        toppedUpValue.alignment = .right
        toppedUpValue.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpValue)

        // Granted row
        grantedLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        grantedLabel.textColor = .secondaryLabelColor
        grantedLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grantedLabel)

        grantedBar.barColor = NSColor.systemGreen
        grantedBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grantedBar)

        grantedValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        grantedValue.textColor = .labelColor
        grantedValue.alignment = .right
        grantedValue.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grantedValue)

        // Buttons
        refreshButton.title = "刷新"
        refreshButton.bezelStyle = .rounded
        refreshButton.controlSize = .small
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.target = self
        refreshButton.action = #selector(refreshTapped)
        addSubview(refreshButton)

        settingsButton.title = "设置"
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .small
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.target = self
        settingsButton.action = #selector(settingsTapped)
        addSubview(settingsButton)

        // Layout
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            balanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            balanceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            stateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),

            // Topped up row
            toppedUpLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            toppedUpLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            toppedUpLabel.widthAnchor.constraint(equalToConstant: 58),

            toppedUpBar.centerYAnchor.constraint(equalTo: toppedUpLabel.centerYAnchor),
            toppedUpBar.leadingAnchor.constraint(equalTo: toppedUpLabel.trailingAnchor, constant: 8),
            toppedUpBar.heightAnchor.constraint(equalToConstant: 6),

            toppedUpValue.centerYAnchor.constraint(equalTo: toppedUpLabel.centerYAnchor),
            toppedUpValue.leadingAnchor.constraint(equalTo: toppedUpBar.trailingAnchor, constant: 8),
            toppedUpValue.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            toppedUpValue.widthAnchor.constraint(equalToConstant: 70),

            // Granted row
            grantedLabel.topAnchor.constraint(equalTo: toppedUpLabel.bottomAnchor, constant: 10),
            grantedLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            grantedLabel.widthAnchor.constraint(equalToConstant: 58),

            grantedBar.centerYAnchor.constraint(equalTo: grantedLabel.centerYAnchor),
            grantedBar.leadingAnchor.constraint(equalTo: grantedLabel.trailingAnchor, constant: 8),
            grantedBar.heightAnchor.constraint(equalToConstant: 6),

            grantedValue.centerYAnchor.constraint(equalTo: grantedLabel.centerYAnchor),
            grantedValue.leadingAnchor.constraint(equalTo: grantedBar.trailingAnchor, constant: 8),
            grantedValue.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            grantedValue.widthAnchor.constraint(equalToConstant: 70),

            // Buttons
            refreshButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            refreshButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            settingsButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])

        showLoading()
    }

    override func updateTrackingAreas() {
        // Triggered by parent to notify about mouse tracking
    }

    func showLoading() {
        stateLabel.stringValue = "查询中..."
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.isHidden = false
        balanceLabel.isHidden = true
        subtitleLabel.isHidden = true
        toppedUpLabel.isHidden = true
        toppedUpBar.isHidden = true
        toppedUpValue.isHidden = true
        grantedLabel.isHidden = true
        grantedBar.isHidden = true
        grantedValue.isHidden = true
    }

    func update(with info: BalanceInfo) {
        stateLabel.isHidden = true
        balanceLabel.isHidden = false
        subtitleLabel.isHidden = false
        toppedUpLabel.isHidden = false
        toppedUpBar.isHidden = false
        toppedUpValue.isHidden = false
        grantedLabel.isHidden = false
        grantedBar.isHidden = false
        grantedValue.isHidden = false

        let total = Double(info.totalBalance) ?? 0
        let toppedUp = Double(info.toppedUpBalance) ?? 0
        let granted = Double(info.grantedBalance) ?? 0

        let symbol = currencySymbol(info.currency)
        balanceLabel.stringValue = "\(symbol) \(formatAmount(info.totalBalance))"

        toppedUpValue.stringValue = "\(symbol) \(formatAmount(info.toppedUpBalance))"
        grantedValue.stringValue = "\(symbol) \(formatAmount(info.grantedBalance))"

        if total > 0 {
            toppedUpBar.progress = CGFloat(toppedUp / total)
            grantedBar.progress = CGFloat(granted / total)
        } else {
            toppedUpBar.progress = 0
            grantedBar.progress = 0
        }
    }

    func showError(_ message: String) {
        stateLabel.stringValue = message
        stateLabel.textColor = .systemRed
        stateLabel.isHidden = false
        balanceLabel.isHidden = true
        subtitleLabel.isHidden = true
        toppedUpLabel.isHidden = true
        toppedUpBar.isHidden = true
        toppedUpValue.isHidden = true
        grantedLabel.isHidden = true
        grantedBar.isHidden = true
        grantedValue.isHidden = true
    }

    func showNoToken() {
        stateLabel.stringValue = "未设置 API Token\n点击设置"
        stateLabel.textColor = .secondaryLabelColor
        stateLabel.isHidden = false
        balanceLabel.isHidden = true
        subtitleLabel.isHidden = true
        toppedUpLabel.isHidden = true
        toppedUpBar.isHidden = true
        toppedUpValue.isHidden = true
        grantedLabel.isHidden = true
        grantedBar.isHidden = true
        grantedValue.isHidden = true
    }

    @objc private func refreshTapped() {
        onRefresh?()
    }

    @objc private func settingsTapped() {
        onChangeToken?()
    }

    private func currencySymbol(_ currency: String) -> String {
        switch currency.uppercased() {
        case "CNY": return "¥"
        case "USD": return "$"
        case "EUR": return "€"
        default: return currency
        }
    }

    private func formatAmount(_ value: String) -> String {
        guard let d = Double(value) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: d)) ?? value
    }
}

class ProgressBarView: NSView {
    var progress: CGFloat = 0 { didSet { needsDisplay = true } }
    var barColor: NSColor = .systemBlue { didSet { needsDisplay = true } }
    var trackColor: NSColor = .separatorColor

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 90, height: 6)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 3, yRadius: 3)
        trackColor.setFill()
        path.fill()

        if progress > 0 {
            let barWidth = bounds.width * progress
            let barRect = NSRect(x: 0, y: 0, width: max(barWidth, 6), height: bounds.height)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 3, yRadius: 3)
            barColor.setFill()
            barPath.fill()
        }
    }
}
