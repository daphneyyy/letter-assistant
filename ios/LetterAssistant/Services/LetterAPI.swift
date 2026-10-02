import Foundation

struct RelayConfiguration {
    let url: URL
    let token: String
    static func load() -> RelayConfiguration? {
        #if DEBUG
        guard let file = Bundle.main.url(forResource: "Debug.local", withExtension: "plist"),
              let data = try? Data(contentsOf: file),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let address = values["RELAY_URL"], let url = URL(string: address),
              let host = url.host, url.scheme == "http", url.user == nil, url.password == nil,
              let token = values["RELAY_TOKEN"], token.count >= 32,
              isLocalHost(host) else { return nil }
        return RelayConfiguration(url: url, token: token)
        #else
        return nil
        #endif
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
struct LetterPageInput { let id: UUID; let image: Data; let token: String }
protocol LetterAPIClient {
    var isConfigured: Bool { get }
    func validate(image: Data, captureID: UUID, pageID: UUID) async throws -> PageValidation
    func interpret(image: Data, captureID: UUID, pageID: UUID, token: String) async throws -> LetterInterpretation
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation
}
extension LetterAPIClient {
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation {
        guard pages.count == 1, let page = pages.first else { throw RelayError(code: "multipage_unavailable") }
        return try await interpret(image: page.image, captureID: captureID, pageID: page.id, token: page.token)
    }
}
struct LetterAPI: LetterAPIClient {
    let configuration: RelayConfiguration?
    var isConfigured: Bool { configuration != nil }
    func validate(image: Data, captureID: UUID, pageID: UUID) async throws -> PageValidation {
        try await post("validate-page", image: image, captureID: captureID, pageID: pageID, validationToken: nil)
    }
    func interpret(image: Data, captureID: UUID, pageID: UUID, token: String) async throws -> LetterInterpretation {
        try await post("interpret", image: image, captureID: captureID, pageID: pageID, validationToken: token)
    }
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation {
        let payload: [String: Any] = ["capture_id": captureID.uuidString, "pages": pages.map {
            ["page_id": $0.id.uuidString, "image_base64": $0.image.base64EncodedString(), "validation_token": $0.token]
        }]
        return try await send("interpret", payload: payload)
    }
    private func post<T: Decodable>(_ path: String, image: Data, captureID: UUID, pageID: UUID, validationToken: String?) async throws -> T {
        var payload: [String: Any] = ["image_base64": image.base64EncodedString(), "capture_id": captureID.uuidString, "page_id": pageID.uuidString]
        if let validationToken { payload["validation_token"] = validationToken }
        return try await send(path, payload: payload)
    }
    private func send<T: Decodable>(_ path: String, payload: [String: Any]) async throws -> T {
        guard let configuration else { throw RelayError(code: "local_setup_missing") }
        var request = URLRequest(url: configuration.url.appendingPathComponent(path))
        request.httpMethod = "POST"; request.timeoutInterval = 125
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RelayError(code: "connection_failed") }
        guard (200..<300).contains(http.statusCode) else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let error = object?["error"] as? [String: Any]
            throw RelayError(code: error?["code"] as? String ?? "request_failed")
        }
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
