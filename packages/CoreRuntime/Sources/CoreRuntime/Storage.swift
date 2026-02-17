import Foundation

public protocol NamespacedStorage {
    func value(forKey key: String) -> String?
    func setValue(_ value: String, forKey key: String)
    func removeValue(forKey key: String)
    func allKeys() -> [String]
}

public final class InMemoryStorageHub {
    private var storage: [String: [String: String]] = [:]
    private let lock = NSLock()

    public init() {}

    public func namespace(_ name: String) -> NamespacedStorage {
        InMemoryNamespacedStorage(namespace: name, hub: self)
    }

    fileprivate func value(namespace: String, key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[namespace]?[key]
    }

    fileprivate func set(namespace: String, key: String, value: String) {
        lock.lock()
        defer { lock.unlock() }
        var bag = storage[namespace] ?? [:]
        bag[key] = value
        storage[namespace] = bag
    }

    fileprivate func remove(namespace: String, key: String) {
        lock.lock()
        defer { lock.unlock() }
        guard var bag = storage[namespace] else { return }
        bag.removeValue(forKey: key)
        storage[namespace] = bag
    }

    fileprivate func keys(namespace: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return (storage[namespace] ?? [:]).keys.sorted()
    }
}

private struct InMemoryNamespacedStorage: NamespacedStorage {
    let namespace: String
    let hub: InMemoryStorageHub

    func value(forKey key: String) -> String? {
        hub.value(namespace: namespace, key: key)
    }

    func setValue(_ value: String, forKey key: String) {
        hub.set(namespace: namespace, key: key, value: value)
    }

    func removeValue(forKey key: String) {
        hub.remove(namespace: namespace, key: key)
    }

    func allKeys() -> [String] {
        hub.keys(namespace: namespace)
    }
}
