import Foundation

public protocol HttpClientProtocol {
    func postJson(
        path: String,
        body: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    )
}

final class HttpClient: HttpClientProtocol {
    private let baseUrl: String
    private let appToken: String
    private let session: URLSession

    init(baseUrl: String, appToken: String, session: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.appToken = appToken
        self.session = session
    }

    func postJson(
        path: String,
        body: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: baseUrl + path) else {
            onFailure(URLError(.badURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appToken, forHTTPHeaderField: "x-app-token")
        request.setValue("MobileHub-iOS/1.0.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body.data(using: .utf8)

        session.dataTask(with: request) { _, response, error in
            if let error = error {
                onFailure(error)
                return
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                onFailure(URLError(.badServerResponse))
                return
            }
            onSuccess()
        }.resume()
    }
}
