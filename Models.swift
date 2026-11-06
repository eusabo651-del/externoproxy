import Foundation

struct PanelConfig: Codable, Identifiable {
    var id: String?
    var esp: Bool
    var name: Bool
    var box: Bool
    var distance: Bool
    var fov: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case esp = "ESP"
        case name = "NAME"
        case box = "BOX"
        case distance = "DISTANCE"
        case fov = "FOV"
    }

    static let `default` = PanelConfig(
        id: nil, esp: false, name: false,
        box: false, distance: false, fov: false
    )
}

struct UrbanKey: Codable, Identifiable {
    var key: String
    var used: Bool?
    var device: String?
    var expire: Int?
    var type: String?
    var createdAt: Int?
    var activatedAt: Int?
    var expiresAt: Int?
    var onlineAt: Int?
    var status: String?
    var username: String?
    var id: String?

    enum CodingKeys: String, CodingKey {
        case key, used, device, expire, type
        case createdAt, activatedAt, expiresAt, onlineAt
        case status, username, id
    }
}
