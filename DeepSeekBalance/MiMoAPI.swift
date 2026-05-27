import Foundation

enum MiMoError: Error {
    case noData
    case unauthorized
    case parseError(String)
    case networkError(Error)
    case httpError(Int)

    var localizedDescription: String {
        switch self {
        case .noData:          return "无响应数据"
        case .unauthorized:    return "Cookie 已过期，请重新登录"
        case .parseError(let m): return "数据解析错误: \(m)"
        case .networkError(let e): return "网络错误: \(e.localizedDescription)"
        case .httpError(let code): return "HTTP 错误: \(code)"
        }
    }
}

struct MiMoUsageInfo {
    let planName: String        // 套餐名称：Lite/Standard/Pro/Max
    let planCode: String        // 套餐代码
    let expired: Bool           // 是否过期
    let expireDate: String      // 到期时间
    let totalUsed: Int64        // 总已用 Credits
    let totalLimit: Int64       // 总限额
    let monthUsed: Int64        // 本月已用
    let monthLimit: Int64       // 本月限额
    let usagePercent: Double    // 使用百分比

    var totalUsedFormatted: String {
        formatCredits(totalUsed)
    }

    var totalLimitFormatted: String {
        formatCredits(totalLimit)
    }

    var monthUsedFormatted: String {
        formatCredits(monthUsed)
    }

    var monthLimitFormatted: String {
        formatCredits(monthLimit)
    }

    private func formatCredits(_ value: Int64) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.1fB", Double(value) / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }
}

struct MiMoAPI {
    private static let baseURL = "https://platform.xiaomimimo.com"

    // MARK: - Cookie 管理

    static func saveCookies(_ cookieString: String) {
        KeychainManager.saveCookie(cookieString, service: "mimo")
    }

    static func loadCookies() -> String? {
        KeychainManager.loadCookie(service: "mimo")
    }

    static func deleteCookies() {
        KeychainManager.deleteCookie(service: "mimo")
    }

    // MARK: - API 调用

    static func fetchUsage(completion: @escaping (Result<MiMoUsageInfo, MiMoError>) -> Void) {
        guard let cookies = loadCookies(), !cookies.isEmpty else {
            completion(.failure(.unauthorized))
            return
        }

        let group = DispatchGroup()
        var usageResult: Result<UsageData, MiMoError> = .failure(.noData)
        var detailResult: Result<DetailData, MiMoError> = .failure(.noData)

        // 并发请求用量和详情
        group.enter()
        fetchTokenPlanUsage(cookies: cookies) { result in
            usageResult = result
            group.leave()
        }

        group.enter()
        fetchTokenPlanDetail(cookies: cookies) { result in
            detailResult = result
            group.leave()
        }

        group.notify(queue: .main) {
            switch (usageResult, detailResult) {
            case (.success(let usage), .success(let detail)):
                let info = MiMoUsageInfo(
                    planName: detail.planName,
                    planCode: detail.planCode,
                    expired: detail.expired,
                    expireDate: detail.currentPeriodEnd,
                    totalUsed: usage.planTotalUsed,
                    totalLimit: usage.planTotalLimit,
                    monthUsed: usage.monthTotalUsed,
                    monthLimit: usage.monthTotalLimit,
                    usagePercent: usage.planPercent
                )
                completion(.success(info))

            case (.failure(let error), _):
                completion(.failure(error))
            case (_, .failure(let error)):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 套餐用量

    private struct UsageData {
        let planPercent: Double
        let planTotalUsed: Int64
        let planTotalLimit: Int64
        let monthPercent: Double
        let monthTotalUsed: Int64
        let monthTotalLimit: Int64
    }

    private static func fetchTokenPlanUsage(cookies: String, completion: @escaping (Result<UsageData, MiMoError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/tokenPlan/usage") else {
            completion(.failure(.parseError("Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(cookies, forHTTPHeaderField: "Cookie")
        request.timeoutInterval = 15

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.noData))
                return
            }

            if httpResponse.statusCode == 401 {
                completion(.failure(.unauthorized))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let code = json["code"] as? Int, code == 0,
                      let dataDict = json["data"] as? [String: Any] else {
                    completion(.failure(.parseError("无效的 JSON 结构")))
                    return
                }

                // 解析 usage（总用量）
                var planPercent: Double = 0
                var planTotalUsed: Int64 = 0
                var planTotalLimit: Int64 = 0

                if let usage = dataDict["usage"] as? [String: Any] {
                    planPercent = usage["percent"] as? Double ?? 0
                    if let items = usage["items"] as? [[String: Any]],
                       let first = items.first {
                        planTotalUsed = first["used"] as? Int64 ?? 0
                        planTotalLimit = first["limit"] as? Int64 ?? 0
                    }
                }

                // 解析 monthUsage（月度用量）
                var monthPercent: Double = 0
                var monthTotalUsed: Int64 = 0
                var monthTotalLimit: Int64 = 0

                if let monthUsage = dataDict["monthUsage"] as? [String: Any] {
                    monthPercent = monthUsage["percent"] as? Double ?? 0
                    if let items = monthUsage["items"] as? [[String: Any]],
                       let first = items.first {
                        monthTotalUsed = first["used"] as? Int64 ?? 0
                        monthTotalLimit = first["limit"] as? Int64 ?? 0
                    }
                }

                let usageData = UsageData(
                    planPercent: planPercent,
                    planTotalUsed: planTotalUsed,
                    planTotalLimit: planTotalLimit,
                    monthPercent: monthPercent,
                    monthTotalUsed: monthTotalUsed,
                    monthTotalLimit: monthTotalLimit
                )
                completion(.success(usageData))
            } catch {
                completion(.failure(.parseError(error.localizedDescription)))
            }
        }
        task.resume()
    }

    // MARK: - 套餐详情

    private struct DetailData {
        let planCode: String
        let planName: String
        let expired: Bool
        let currentPeriodEnd: String
    }

    private static func fetchTokenPlanDetail(cookies: String, completion: @escaping (Result<DetailData, MiMoError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/tokenPlan/detail") else {
            completion(.failure(.parseError("Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(cookies, forHTTPHeaderField: "Cookie")
        request.timeoutInterval = 15

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.noData))
                return
            }

            if httpResponse.statusCode == 401 {
                completion(.failure(.unauthorized))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let code = json["code"] as? Int, code == 0,
                      let dataDict = json["data"] as? [String: Any] else {
                    completion(.failure(.parseError("无效的 JSON 结构")))
                    return
                }

                let planCode = dataDict["planCode"] as? String ?? ""
                let planName = dataDict["planName"] as? String ?? ""
                let expired = dataDict["expired"] as? Bool ?? false
                let currentPeriodEnd = dataDict["currentPeriodEnd"] as? String ?? ""

                let detail = DetailData(
                    planCode: planCode,
                    planName: planName,
                    expired: expired,
                    currentPeriodEnd: currentPeriodEnd
                )
                completion(.success(detail))
            } catch {
                completion(.failure(.parseError(error.localizedDescription)))
            }
        }
        task.resume()
    }
}
