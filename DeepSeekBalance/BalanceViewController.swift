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
        preferredContentSize = NSSize(width: 280, height: 200)
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
    private let titleLabel = NSTextField()
    private let balanceLabel = NSTextField()
    private let subtitleLabel = NSTextField()

    private let toppedUpLabel = NSTextField()
    private let toppedUpBar = ProgressBarView()
    private let toppedUpValue = NSTextField()

    private let grantedLabel = NSTextField()
    private let grantedBar = ProgressBarView()
    private let grantedValue = NSTextField()

    private let refreshButton = NSButton()
    private let settingsButton = NSButton()

    private var stateLabel = NSTextField()
    private let tipLabel = NSTextField()

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
        titleLabel.stringValue = "DeepSeek 余额"
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Balance (large number)
        balanceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        balanceLabel.textColor = .labelColor
        balanceLabel.alignment = .center
        balanceLabel.isEditable = false
        balanceLabel.isSelectable = false
        balanceLabel.isBordered = false
        balanceLabel.drawsBackground = false
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(balanceLabel)

        // Subtitle
        subtitleLabel.stringValue = "总余额"
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .tertiaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.isEditable = false
        subtitleLabel.isSelectable = false
        subtitleLabel.isBordered = false
        subtitleLabel.drawsBackground = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

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

        // Topped up row
        toppedUpLabel.stringValue = "充值余额"
        toppedUpLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        toppedUpLabel.textColor = .secondaryLabelColor
        toppedUpLabel.isEditable = false
        toppedUpLabel.isSelectable = false
        toppedUpLabel.isBordered = false
        toppedUpLabel.drawsBackground = false
        toppedUpLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpLabel)

        toppedUpBar.barColor = NSColor.systemBlue
        toppedUpBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpBar)

        toppedUpValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        toppedUpValue.textColor = .labelColor
        toppedUpValue.alignment = .right
        toppedUpValue.isEditable = false
        toppedUpValue.isSelectable = false
        toppedUpValue.isBordered = false
        toppedUpValue.drawsBackground = false
        toppedUpValue.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toppedUpValue)

        // Granted row
        grantedLabel.stringValue = "赠送余额"
        grantedLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        grantedLabel.textColor = .secondaryLabelColor
        grantedLabel.isEditable = false
        grantedLabel.isSelectable = false
        grantedLabel.isBordered = false
        grantedLabel.drawsBackground = false
        grantedLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grantedLabel)

        grantedBar.barColor = NSColor.systemGreen
        grantedBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grantedBar)

        grantedValue.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        grantedValue.textColor = .labelColor
        grantedValue.alignment = .right
        grantedValue.isEditable = false
        grantedValue.isSelectable = false
        grantedValue.isBordered = false
        grantedValue.drawsBackground = false
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

            balanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            balanceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            stateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

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

            // Tip label
            tipLabel.topAnchor.constraint(equalTo: grantedValue.bottomAnchor, constant: 12),
            tipLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            // Buttons
            refreshButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            refreshButton.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 6),

            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            settingsButton.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 6),
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
