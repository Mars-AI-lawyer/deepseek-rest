import Foundation

enum DeepSeekError: Error {
    case noData
    case unauthorized
    case parseError(String)
    case networkError(Error)
    case httpError(Int)

    var localizedDescription: String {
        switch self {
        case .noData:          return "无响应数据"
        case .unauthorized:    return "Token 无效，请重新输入"
        case .parseError(let m): return "数据解析错误: \(m)"
        case .networkError(let e): return "网络错误: \(e.localizedDescription)"
        case .httpError(let code): return "HTTP 错误: \(code)"
        }
    }
}

struct BalanceInfo {
    let currency: String
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String
}

struct DeepSeekAPI {
    private static let endpoint = "https://api.deepseek.com/user/balance"

    static func fetchBalance(token: String, completion: @escaping (Result<BalanceInfo, DeepSeekError>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.parseError("Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                guard let json = json,
                      let infos = json["balance_infos"] as? [[String: Any]],
                      let first = infos.first else {
                    completion(.failure(.parseError("无法解析余额数据")))
                    return
                }

                guard let currency = first["currency"] as? String,
                      let total = first["total_balance"] as? String,
                      let granted = first["granted_balance"] as? String,
                      let toppedUp = first["topped_up_balance"] as? String else {
                    completion(.failure(.parseError("余额字段缺失")))
                    return
                }

                let info = BalanceInfo(
                    currency: currency,
                    totalBalance: total,
                    grantedBalance: granted,
                    toppedUpBalance: toppedUp
                )
                completion(.success(info))
            } catch {
                completion(.failure(.parseError(error.localizedDescription)))
            }
        }
        task.resume()
    }
}
