import Foundation
@testable import MobileHub

final class FakeHttpClient: HttpClientProtocol {
    struct Call {
        let path: String
        let body: String
    }

    var calls: [Call] = []
    var shouldFail = false
    var onPost: (() -> Void)?

    func postJson(
        path: String,
        body: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        calls.append(Call(path: path, body: body))
        onPost?()
        if shouldFail {
            onFailure(URLError(.notConnectedToInternet))
        } else {
            onSuccess()
        }
    }

    var callCount: Int { calls.count }
    var lastBody: String? { calls.last?.body }
    var lastPath: String? { calls.last?.path }
}
