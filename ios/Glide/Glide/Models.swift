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

// GroupMember has a composite PK (group_id, user_id) — no id column in DB.
// A computed id is provided for SwiftUI Identifiable conformance.
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
