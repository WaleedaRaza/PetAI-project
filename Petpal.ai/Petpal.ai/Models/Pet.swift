import Foundation

struct Pet: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let age: Int
    let species: String
    let breed: String
    let createdAt: Date
}
