import AppKit
import WebKit

class MiMoLoginWindowController: NSWindowController {

    private var webView: WKWebView!
    private var progressIndicator: NSProgressIndicator!
    private var statusLabel: NSTextField!

    var onLoginSuccess: ((String) -> Void)?
    var onLoginCancel: (() -> Void)?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MiMo 登录"
        window.center()
        window.minSize = NSSize(width: 400, height: 500)

        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // 顶部提示栏
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)

        statusLabel = NSTextField(labelWithString: "请登录小米账号以获取 MiMo 套餐信息")
        statusLabel.font = NSFont.systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(statusLabel)

        // 进度指示器
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressIndicator)

        // WebView 配置
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(webView)

        // 底部按钮栏
        let bottomBar = NSView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomBar)

        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelTapped))
        cancelButton.bezelStyle = .rounded
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(cancelButton)

        // 布局
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            statusLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            progressIndicator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            progressIndicator.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 44),

            cancelButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            cancelButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
        ])

        // 加载 MiMo 登录页面
        if let url = URL(string: "https://platform.xiaomimimo.com") {
            webView.load(URLRequest(url: url))
        }
    }

    @objc private func cancelTapped() {
        window?.close()
        onLoginCancel?()
    }

    private func checkLoginStatus() {
        // 检查 WebView 中的 Cookie
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            var cookieDict: [String: String] = [:]
            for cookie in cookies {
                if cookie.domain.contains("xiaomimimo.com") {
                    cookieDict[cookie.name] = cookie.value
                }
            }

            // 检查是否包含关键 Cookie（serviceToken 或其他认证标识）
            let hasAuthToken = cookieDict.keys.contains { key in
                key.lowercased().contains("servicetoken") ||
                key.lowercased().contains("token") ||
                key.lowercased().contains("auth")
            }

            DispatchQueue.main.async {
                if hasAuthToken {
                    // 登录成功，构建 Cookie 字符串
                    let cookieString = cookieDict.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
                    self?.statusLabel.stringValue = "登录成功！正在保存..."
                    self?.statusLabel.textColor = .systemGreen
                    self?.progressIndicator.isHidden = false
                    self?.progressIndicator.startAnimation(nil)

                    // 延迟关闭，让用户看到成功提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.window?.close()
                        self?.onLoginSuccess?(cookieString)
                    }
                }
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension MiMoLoginWindowController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "加载中..."
        statusLabel.textColor = .secondaryLabelColor
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)

        // 页面加载完成后检查登录状态
        checkLoginStatus()

        // 持续监听 Cookie 变化
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard self != nil, self?.window?.isVisible == true else {
                timer.invalidate()
                return
            }
            self?.checkLoginStatus()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)
        statusLabel.stringValue = "加载失败: \(error.localizedDescription)"
        statusLabel.textColor = .systemRed
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}
