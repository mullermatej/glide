import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var displayName: String?
    var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct TripGroup: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let createdBy: UUID?
    var name: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case createdBy = "created_by"
        case name
    }
}

struct GroupMember: Codable, Identifiable {
    let groupId: UUID
    let userId: UUID
    let joinedAt: Date

    var id: String { "\(groupId)_\(userId)" }

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

struct Trip: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let createdBy: UUID?
    let groupId: UUID
    var name: String
    var destination: String?
    var startDate: Date?
    var endDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case createdBy = "created_by"
        case groupId = "group_id"
        case name
        case destination
        case startDate = "start_date"
        case endDate = "end_date"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
        groupId = try container.decode(UUID.self, forKey: .groupId)
        name = try container.decode(String.self, forKey: .name)
        destination = try container.decodeIfPresent(String.self, forKey: .destination)

        if let raw = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = Self.dateOnlyFormatter.date(from: raw)
        } else {
            startDate = nil
        }
        if let raw = try container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = Self.dateOnlyFormatter.date(from: raw)
        } else {
            endDate = nil
        }
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}

struct Event: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let createdBy: UUID?
    let tripId: UUID
    var title: String
    var description: String?
    var scheduledAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case createdBy = "created_by"
        case tripId = "trip_id"
        case title
        case description
        case scheduledAt = "scheduled_at"
    }
}
