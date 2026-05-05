import Combine
import Foundation

@MainActor
protocol PowerMonitoring: AnyObject {
    var snapshot: PowerSourceSnapshot { get }
    var snapshotPublisher: AnyPublisher<PowerSourceSnapshot, Never> { get }

    func refresh()
}
