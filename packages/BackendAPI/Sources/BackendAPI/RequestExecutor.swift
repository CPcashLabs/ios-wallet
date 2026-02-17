import Foundation

public protocol TokenStore: AnyObject {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }
}

public final class UserDefaultsTokenStore: TokenStore {
    private let accessKey: String
    private let refreshKey: String
    private let defaults: UserDefaults

    public init(
        accessKey: String = "cpcash.accessToken",
        refreshKey: String = "cpcash.refreshToken",
        defaults: UserDefaults = .standard
    ) {
        self.accessKey = accessKey
        self.refreshKey = refreshKey
        self.defaults = defaults
    }

    public var accessToken: String? {
        get { defaults.string(forKey: accessKey) }
        set { defaults.set(newValue, forKey: accessKey) }
    }

    public var refreshToken: String? {
        get { defaults.string(forKey: refreshKey) }
        set { defaults.set(newValue, forKey: refreshKey) }
    }
}

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

public final class RequestExecutor {
    public let environment: EnvironmentConfig
    private let session: URLSession
    private let tokenStore: TokenStore

    public init(environment: EnvironmentConfig, tokenStore: TokenStore, session: URLSession = .shared) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.session = session
    }

    public func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        jsonBody: [String: JSONValue]? = nil,
        formBody: [String: String]? = nil,
        requiresAuth: Bool = true,
        responseType: T.Type = T.self
    ) async throws -> APIEnvelope<T> {
        let data = try await rawRequest(
            method: method,
            path: path,
            query: query,
            jsonBody: jsonBody,
            formBody: formBody,
            requiresAuth: requiresAuth
        )

        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)

        if envelope.code == 401 {
            throw BackendAPIError.unauthorized
        }

        guard envelope.code == 200 else {
            throw BackendAPIError.serverError(code: envelope.code, message: envelope.message ?? "Unknown backend error")
        }

        return envelope
    }

    public func rawRequest(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        jsonBody: [String: JSONValue]? = nil,
        formBody: [String: String]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Data {
        try assertEnvironmentHost()

        guard var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: false) else {
            throw BackendAPIError.invalidURL
        }

        components.path = normalizedPath(components.path, path)
        if !query.isEmpty {
            components.queryItems = query
        }

        guard let url = components.url else {
            throw BackendAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")

        if requiresAuth, let token = tokenStore.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let formBody {
            request.httpBody = encodeFormBody(formBody)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        } else if let jsonBody {
            request.httpBody = try JSONEncoder().encode(jsonBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        print("[BackendAPI][\(environment.tag.rawValue)] \(method.rawValue) \(url.absoluteString)")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BackendAPIError.httpStatus(-1)
        }

        if http.statusCode == 401 {
            throw BackendAPIError.unauthorized
        }

        guard (200 ... 299).contains(http.statusCode) else {
            throw BackendAPIError.httpStatus(http.statusCode)
        }

        return data
    }

    public func rawMultipartRequest(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        formFields: [String: String],
        requiresAuth: Bool = true
    ) async throws -> Data {
        try assertEnvironmentHost()

        guard var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: false) else {
            throw BackendAPIError.invalidURL
        }

        components.path = normalizedPath(components.path, path)
        if !query.isEmpty {
            components.queryItems = query
        }

        guard let url = components.url else {
            throw BackendAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")

        if requiresAuth, let token = tokenStore.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodeMultipartBody(
            boundary: boundary,
            formFields: formFields,
            fileFieldName: fileFieldName,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData
        )

        print("[BackendAPI][\(environment.tag.rawValue)] \(method.rawValue) \(url.absoluteString)")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BackendAPIError.httpStatus(-1)
        }

        if http.statusCode == 401 {
            throw BackendAPIError.unauthorized
        }

        guard (200 ... 299).contains(http.statusCode) else {
            throw BackendAPIError.httpStatus(http.statusCode)
        }

        return data
    }

    public func saveToken(_ token: SessionToken) {
        tokenStore.accessToken = token.accessToken
        tokenStore.refreshToken = token.refreshToken
    }

    public func clearToken() {
        tokenStore.accessToken = nil
        tokenStore.refreshToken = nil
    }

    private func normalizedPath(_ basePath: String, _ path: String) -> String {
        var composed = basePath
        if !composed.hasSuffix("/") {
            composed += "/"
        }

        if path.hasPrefix("/") {
            return composed + String(path.dropFirst())
        }

        return composed + path
    }

    private func encodeFormBody(_ form: [String: String]) -> Data {
        let value = form
            .map { key, raw in
                "\(percentEncode(key))=\(percentEncode(raw))"
            }
            .sorted()
            .joined(separator: "&")
        return Data(value.utf8)
    }

    private func encodeMultipartBody(
        boundary: String,
        formFields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (key, value) in formFields {
            body.append(Data("--\(boundary)\(lineBreak)".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".utf8))
            body.append(Data("\(value)\(lineBreak)".utf8))
        }

        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\(lineBreak)".utf8))
        body.append(Data("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".utf8))
        body.append(fileData)
        body.append(Data(lineBreak.utf8))
        body.append(Data("--\(boundary)--\(lineBreak)".utf8))

        return body
    }

    private func percentEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func assertEnvironmentHost() throws {
        let actualHost = environment.baseURL.host?.lowercased() ?? ""
        let expectedHost: String
        switch environment.tag {
        case .development, .staging:
            expectedHost = "charprotocol.dev"
        case .production:
            expectedHost = "cp.cash"
        }

        guard actualHost == expectedHost else {
            throw BackendAPIError.invalidEnvironmentHost(expected: expectedHost, actual: actualHost)
        }
    }
}
