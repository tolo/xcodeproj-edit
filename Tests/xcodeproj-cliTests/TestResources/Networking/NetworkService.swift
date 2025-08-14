// Network Service using Alamofire
import Foundation
import Alamofire

class NetworkService {
  static let shared = NetworkService()
  
  func request<T: Codable>(_ endpoint: String, type: T.Type) async throws -> T {
    // Network request logic using Alamofire
    fatalError("Not implemented")
  }
}