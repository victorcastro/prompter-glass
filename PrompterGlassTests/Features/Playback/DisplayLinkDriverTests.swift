import AppKit
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Display link driver")
struct DisplayLinkDriverTests {
    @Test("The driver deallocates even while a link is running")
    func deallocatesWhileRunning() {
        var driver: DisplayLinkDriver? = DisplayLinkDriver(source: { nil }, onTick: { _ in })
        weak var leaked = driver

        driver?.start()
        driver = nil

        #expect(leaked == nil)
    }

    @Test("The driver deallocates when stopped")
    func deallocatesWhenStopped() {
        var driver: DisplayLinkDriver? = DisplayLinkDriver(source: { nil }, onTick: { _ in })
        weak var leaked = driver

        driver?.start()
        driver?.stop()
        driver = nil

        #expect(leaked == nil)
    }

    @Test("Stopping reports not running")
    func stopClearsRunningState() {
        let driver = DisplayLinkDriver(source: { nil }, onTick: { _ in })

        driver.start()
        driver.stop()

        #expect(driver.isRunning == false)
    }

    @Test("Ticks report the elapsed time between timestamps")
    func ticksReportElapsedTime() {
        var deltas: [TimeInterval] = []
        let driver = DisplayLinkDriver(source: { nil }, onTick: { deltas.append($0) })

        driver.processTick(timestamp: 10.0)
        driver.processTick(timestamp: 10.016)
        driver.processTick(timestamp: 10.032)

        #expect(deltas.count == 2)
        #expect(abs(deltas[0] - 0.016) < 0.0001)
        #expect(abs(deltas[1] - 0.016) < 0.0001)
    }

    @Test("A long stall is clamped so the script does not jump")
    func longStallIsClamped() {
        var deltas: [TimeInterval] = []
        let driver = DisplayLinkDriver(source: { nil }, onTick: { deltas.append($0) })

        driver.processTick(timestamp: 10.0)
        driver.processTick(timestamp: 20.0)

        #expect(deltas == [0.25])
    }

    @Test("Out-of-order timestamps do not tick")
    func outOfOrderTimestampsDoNotTick() {
        var deltas: [TimeInterval] = []
        let driver = DisplayLinkDriver(source: { nil }, onTick: { deltas.append($0) })

        driver.processTick(timestamp: 10.0)
        driver.processTick(timestamp: 9.0)

        #expect(deltas.isEmpty)
    }
}
