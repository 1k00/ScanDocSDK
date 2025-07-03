import Foundation

struct AuthenticateRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case userKey = "user_key"
        case subClient = "sub_client"
    }

    let userKey: String
    let subClient: String
}
