import Foundation

@propertyWrapper
final class Atomic<Value> {

    private let queue = DispatchQueue(label: "com.scandoc.atomic", qos: .userInitiated)
    private var value: Value

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        return queue.sync { mutation(&value) }
    }
}
