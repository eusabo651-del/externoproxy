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

struct LicenseKey: Codable, Identifiable {
    var id: String?
    var key: String
    var active: Bool
    var user: String?
}
