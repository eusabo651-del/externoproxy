import Foundation
import UIKit

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkUnavailable
    case licenseNotFound
    case licenseInactive
    case licenseUsedByAnother
    case licenseExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "API address invalid."
        case .noData: return "Server returned no data."
        case .decodingError: return "Failed to parse data."
        case .networkUnavailable: return "Network unavailable."
        case .licenseNotFound: return "License key not found."
        case .licenseInactive: return "License is not active."
        case .licenseUsedByAnother: return "License already bound to another device."
        case .licenseExpired: return "License expired."
        }
    }
}

final class APIService {
    static let shared = APIService()

    private let panelBase = "https://6add1728fa5e73d4ab2ddf15.mockapi.io"
    private let keysBase  = "https://6acfc53303feaa52b21eece9.mockapi.io"
    private let session = URLSession.shared

    private init() {}

    // MARK: - Device ID (HWID)
    var deviceID: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    }

    // MARK: - Panel
    func fetchPanelConfig() async throws -> PanelConfig {
        guard let url = URL(string: "\(panelBase)/painel") else { throw APIError.invalidURL }
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
              let url = URL(string: "\(panelBase)/painel/\(id)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(config)
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw APIError.networkUnavailable
        }
    }

    // MARK: - License (urbanreload)
    private func fetchAllKeys() async throws -> [UrbanKey] {
        guard let url = URL(string: "\(keysBase)/urbanreload") else {
            throw APIError.invalidURL
        }
        let (data, _) = try await session.data(from: url)
        guard !data.isEmpty else { throw APIError.noData }
        do {
            return try JSONDecoder().decode([UrbanKey].self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Valida a key. Se for primeira ativação, grava o device na API.
    /// Retorna a licença atualizada.
    @discardableResult
    func activateOrValidate(key inputKey: String) async throws -> UrbanKey {
        let trimmed = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = try await fetchAllKeys()

        guard let index = all.firstIndex(where: {
            $0.key.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) else {
            throw APIError.licenseNotFound
        }

        var license = all[index]

        // Status
        if let status = license.status, status != "active" {
            throw APIError.licenseInactive
        }

        // Expiração (daily)
        if let exp = license.expire, exp == 1,
           let expAt = license.expiresAt, expAt > 0 {
            let now = Int(Date().timeIntervalSince1970)
            if now > expAt {
                throw APIError.licenseExpired
            }
        }

        let myDevice = deviceID

        // Já usada?
        if license.used == true {
            if let boundDevice = license.device, !boundDevice.isEmpty, boundDevice != myDevice {
                throw APIError.licenseUsedByAnother
            }
            // Mesmo device (ou device vazio na API) → só atualiza onlineAt
            license.onlineAt = Int(Date().timeIntervalSince1970)
            try await putKey(license, id: license.id ?? "")
            return license
        }

        // Primeira ativação → grava device + used
        let now = Int(Date().timeIntervalSince1970)
        license.used = true
        license.device = myDevice
        license.status = "active"
        license.activatedAt = now
        license.onlineAt = now

        // expiresAt: se daily e ainda zero, define +24h
        if (license.expire ?? 0) == 1 && (license.expiresAt ?? 0) == 0 {
            license.expiresAt = now + 24 * 60 * 60
        }

        guard let id = license.id, !id.isEmpty else {
            throw APIError.invalidURL
        }
        try await putKey(license, id: id)
        return license
    }

    private func putKey(_ license: UrbanKey, id: String) async throws {
        guard !id.isEmpty,
              let url = URL(string: "\(keysBase)/urbanreload/\(id)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(license)
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw APIError.networkUnavailable
        }
    }
}

@MainActor
final class LicenseManager: ObservableObject {
    @Published var isValidated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var license: UrbanKey?

    func validate(key: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIService.shared.activateOrValidate(key: key)
            self.license = result
            self.isValidated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
