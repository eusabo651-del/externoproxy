import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "API address invalid."
        case .noData: return "Server returned no data."
        case .decodingError: return "Failed to parse data."
        case .networkUnavailable: return "Network unavailable."
        }
    }
}

final class APIService {
    static let shared = APIService()
    private let baseURL = "https://6add1728fa5e73d4ab2ddf15.mockapi.io"
    private let session = URLSession.shared
    private init() {}

    func fetchPanelConfig() async throws -> PanelConfig {
        guard let url = URL(string: "\(baseURL)/painel") else { throw APIError.invalidURL }
        let (data, _) = try await session.data(from: url)
        guard !data.isEmpty else { throw APIError.noData }
        do {
            let configs = try JSONDecoder().decode([PanelConfig].self, from: data)
            return configs.first ?? .default
        } catch {
            throw APIError.decodingError
        }
    }

    func updatePanelConfig(_ config: PanelConfig) async throws {
        guard let id = config.id,
              let url = URL(string: "\(baseURL)/painel/\(id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(config)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw APIError.networkUnavailable
        }
    }

    func validateLicense(key: String) async throws -> LicenseKey? {
        guard let url = URL(string: "\(baseURL)/ipkeys") else { throw APIError.invalidURL }
        let (data, _) = try await session.data(from: url)
        let keys = try JSONDecoder().decode([LicenseKey].self, from: data)
        return keys.first { $0.key == key && $0.active }
    }
}

@MainActor
final class LicenseManager: ObservableObject {
    @Published var isValidated = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    func validate(key: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIService.shared.validateLicense(key: key)
            if result != nil { isValidated = true }
            else { errorMessage = "Invalid or expired license." }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
