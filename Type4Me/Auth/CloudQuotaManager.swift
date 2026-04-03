import Foundation
import os

@MainActor
final class CloudQuotaManager: ObservableObject {
    static let shared = CloudQuotaManager()

    @Published private(set) var plan: String = "free"
    @Published private(set) var isPaid: Bool = false
    @Published private(set) var freeCharsRemaining: Int = 2000
    @Published private(set) var expiresAt: Date?
    @Published private(set) var weekChars: Int = 0
    @Published private(set) var totalChars: Int = 0

    private let logger = Logger(subsystem: "com.type4me.app", category: "CloudQuota")
    private var lastFetched: Date?

    private init() {}

    /// Refresh quota and usage data from the server.
    /// Skips if fetched less than 30 seconds ago unless `force` is true.
    func refresh(force: Bool = false) async {
        if !force, let last = lastFetched, Date().timeIntervalSince(last) < 30 { return }

        guard let token = await CloudAuthManager.shared.accessToken() else { return }
        let base = CloudConfig.apiEndpoint

        // Fetch quota
        do {
            var req = URLRequest(url: URL(string: "\(base)/api/quota")!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.data(for: req)
            struct QuotaResponse: Decodable {
                let plan: String
                let is_paid: Bool
                let remaining_chars: Int
                let expires_at: String?
            }
            let r = try JSONDecoder().decode(QuotaResponse.self, from: data)
            plan = r.plan
            isPaid = r.is_paid
            freeCharsRemaining = r.remaining_chars
            if let e = r.expires_at {
                expiresAt = ISO8601DateFormatter().date(from: e)
            }
        } catch {
            logger.error("Quota fetch failed: \(error)")
        }

        // Fetch usage
        do {
            var req = URLRequest(url: URL(string: "\(base)/api/usage")!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.data(for: req)
            struct UsageResponse: Decodable {
                let total_chars: Int
                let week_chars: Int
            }
            let r = try JSONDecoder().decode(UsageResponse.self, from: data)
            weekChars = r.week_chars
            totalChars = r.total_chars
        } catch {
            logger.error("Usage fetch failed: \(error)")
        }

        lastFetched = Date()
    }

    /// Check if the user can still use cloud services.
    func canUse() async -> Bool {
        await refresh()
        return isPaid || freeCharsRemaining > 0
    }

    /// Optimistically deduct characters locally (server is authoritative).
    func deductLocal(chars: Int) {
        if !isPaid {
            freeCharsRemaining = max(0, freeCharsRemaining - chars)
        }
        weekChars += chars
        totalChars += chars
    }
}
