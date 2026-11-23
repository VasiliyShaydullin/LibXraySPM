import XCTest
@testable import VlessSPM

final class LibXraySPMTests: XCTestCase {
    func testVersionAndRawInvoke() throws {
        let version = try VlessSPM.version()
        XCTAssertTrue(version.success)
        XCTAssertEqual(version.data?.version, "26.11.9")

        let response = try VlessSPM.invoke(#"{"apiVersion":2,"method":"xrayVersion"}"#)
        XCTAssertTrue(response.contains("unsupported apiVersion"))
        XCTAssertThrowsError(try VlessSPM.invoke("abc\0def"))
    }

    func testPortsAndErrors() throws {
        XCTAssertEqual(try VlessSPM.freePorts(0), [])
        let ports = try VlessSPM.freePorts(2, excluding: [1])
        XCTAssertEqual(Set(ports).count, 2)
        XCTAssertFalse(ports.contains(1))
        XCTAssertThrowsError(try VlessSPM.freePorts(-1))
    }

    func testConfigurationAndState() throws {
        let invalid = try VlessSPM.test(xrayJson: "not json")
        XCTAssertFalse(invalid.success)
        XCTAssertFalse(invalid.error?.isEmpty ?? true)
        XCTAssertTrue(try VlessSPM.stop().success)
        XCTAssertEqual(try VlessSPM.state().data?.running, false)
        let config = #"{"outbounds":[{"protocol":"freedom","tag":"direct"}]}"#
        XCTAssertTrue(try VlessSPM.test(xrayJson: config).success)
        XCTAssertTrue(try VlessSPM.run(xrayJson: config).success)
        XCTAssertEqual(try VlessSPM.state().data?.running, true)
        XCTAssertTrue(try VlessSPM.stop().success)
        XCTAssertEqual(try VlessSPM.state().data?.running, false)
    }

    func testGenericInvokeAndPingFailure() throws {
        struct Payload: Encodable { let text: String }
        struct Result: Decodable { let text: String }
        let response = try VlessSPM.invoke(
            method: "decodeSubscriptionText",
            payload: Payload(text: "hello"),
            dataType: Result.self
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data?.text, "hello")

        let ping = try VlessSPM.pingBatch([], timeout: 1, url: "https://example.com/")
        XCTAssertFalse(ping.success)
        XCTAssertFalse(ping.error?.isEmpty ?? true)
    }
}
