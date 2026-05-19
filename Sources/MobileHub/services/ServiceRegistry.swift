import Foundation

final class ServiceRegistry {
    private var services: [MobileHubService] = []
    private var started = false

    func register(_ service: MobileHubService) {
        guard !started else {
            preconditionFailure("Cannot register services after start() has been called")
        }
        services.append(service)
    }

    func start() {
        guard !started else {
            preconditionFailure("ServiceRegistry has already been started")
        }
        started = true
        for service in services {
            service.onStart()
        }
    }

    func stop() {
        guard started else { return }
        started = false
        for service in services.reversed() {
            service.onStop()
        }
    }

    func get<T: MobileHubService>(_ type: T.Type) -> T? {
        services.first { $0 is T } as? T
    }
}
