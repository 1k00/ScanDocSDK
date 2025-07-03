import Foundation

struct AuthenticateRefreshRequest: Encodable {

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }

    let refreshToken: String
}
