import Foundation

struct AuthenticateRefreshResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }

    let accessToken: String
}
