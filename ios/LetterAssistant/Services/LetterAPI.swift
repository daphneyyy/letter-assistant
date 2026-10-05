import Foundation

struct RelayConfiguration {
    let url: URL
    let token: String
    static func load() -> RelayConfiguration? {
        #if TEST_BUILD
        let configName = "Debug.local"
        #else
        let configName = "Prod.local"
        #endif
        guard let file = Bundle.main.url(forResource: configName, withExtension: "plist"),
              let data = try? Data(contentsOf: file),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let address = values["RELAY_URL"], let url = URL(string: address),
              let host = url.host, url.user == nil, url.password == nil,
              let token = values["RELAY_TOKEN"], token.count >= 32 else { return nil }
        #if TEST_BUILD
        guard url.scheme == "http", isLocalHost(host) else { return nil }
        #else
        guard url.scheme == "https" || (url.scheme == "http" && isLocalHost(host)) else { return nil }
        #endif
        return RelayConfiguration(url: url, token: token)
    }

    static func isLocalHost(_ host: String) -> Bool {
        if host == "localhost" || host == "127.0.0.1" || host.hasSuffix(".local") { return true }
        let components = host.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 4 else { return false }
        let octets = components.compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) else { return false }
        return octets[0] == 10 || (octets[0] == 192 && octets[1] == 168) || (octets[0] == 172 && (16...31).contains(octets[1]))
    }
}
struct RelayError: Error { let code: String }
struct LetterPageInput { let id: UUID; let image: Data }
protocol LetterAPIClient {
    var isConfigured: Bool { get }
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation
    func interpret(pages: [LetterPageInput], captureID: UUID, language: AppLanguage) async throws -> LetterInterpretation
}
extension LetterAPIClient {
    func interpret(pages: [LetterPageInput], captureID: UUID, language: AppLanguage) async throws -> LetterInterpretation {
        try await interpret(pages: pages, captureID: captureID)
    }
}
struct LetterAPI: LetterAPIClient {
    let configuration: RelayConfiguration?
    var isConfigured: Bool { configuration != nil }
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation {
        try await interpret(pages: pages, captureID: captureID, language: .en)
    }
    func interpret(pages: [LetterPageInput], captureID: UUID, language: AppLanguage) async throws -> LetterInterpretation {
        let payload: [String: Any] = ["capture_id": captureID.uuidString, "language": language.rawValue, "pages": pages.map {
            ["page_id": $0.id.uuidString, "image_base64": $0.image.base64EncodedString(), "local_readability": true] as [String: Any]
        }]
        return try await send("interpret", payload: payload)
    }
    private func send<T: Decodable>(_ path: String, payload: [String: Any]) async throws -> T {
        guard let configuration else { throw RelayError(code: "local_setup_missing") }
        var request = URLRequest(url: configuration.url.appendingPathComponent(path))
        request.httpMethod = "POST"; request.timeoutInterval = 125
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 125
        sessionConfig.timeoutIntervalForResource = 150
        let session = URLSession(configuration: sessionConfig)
        defer { session.finishTasksAndInvalidate() }
        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch let error as URLError {
            throw RelayError(code: error.code == .timedOut ? "connection_timeout" : "connection_failed")
        }
        guard let http = response as? HTTPURLResponse else { throw RelayError(code: "connection_failed") }
        guard (200..<300).contains(http.statusCode) else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let error = object?["error"] as? [String: Any]
            throw RelayError(code: error?["code"] as? String ?? "request_failed")
        }
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        do { return try decoder.decode(T.self, from: data) }
        catch { throw RelayError(code: "invalid_relay_response") }
    }
}
