import Darwin
import Foundation
import XCTest
@testable import VlessSPM

final class LibXraySPMTests: XCTestCase {
    private static let lifecycleLock = DispatchSemaphore(value: 1)

    override func setUp() {
        super.setUp()
        Self.lifecycleLock.wait()
        XCTAssertTrue(try VlessSPM.stop().success)
    }

    override func tearDown() {
        XCTAssertTrue(try VlessSPM.stop().success)
        Self.lifecycleLock.signal()
        super.tearDown()
    }

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
        defer {
            XCTAssertTrue(try VlessSPM.stop().success)
        }
        XCTAssertEqual(try VlessSPM.state().data?.running, true)
        let ping = try VlessSPM.pingBatch(
            [PingBatchItem(xrayJson: config)], timeout: 1, url: "http://127.0.0.1/"
        )
        XCTAssertFalse(ping.success)
        XCTAssertFalse(ping.error?.isEmpty ?? true)
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

    func testResponsesCanCrossConcurrencyDomains() async throws {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(EmptyPayload.self)
        requireSendable(EmptyResponse.self)
        requireSendable(XrayVersion.self)
        requireSendable(XrayState.self)
        requireSendable(SubscriptionText.self)
        requireSendable(ShareLinks.self)
        requireSendable(LibXrayError.self)

        let item = PingBatchItem(xrayJson: "{}")
        let response = try await Task.detached {
            try VlessSPM.pingBatch([item], timeout: 0, url: "http://127.0.0.1/")
        }.value
        XCTAssertFalse(response.success)
        XCTAssertFalse(response.error?.isEmpty ?? true)
    }

    func testSubscriptionsAndShareLinks() throws {
        struct Config: Decodable {
            struct Outbound: Decodable {
                let `protocol`: String
                let tag: String
            }
            let outbounds: [Outbound]
        }

        let link = "vless://12345678-abcd-abcd-abcd-123456789abc@example.com:443?encryption=none&security=tls&sni=example.com#Example"
        let text = try VlessSPM.decodeSubscriptionText(link)
        XCTAssertTrue(text.success)
        XCTAssertEqual(text.data?.text, link)

        let armor = "-----BEGIN AGE ENCRYPTED FILE-----\n"
        let missingKey = try VlessSPM.decodeSubscriptionText(armor)
        let invalidKey = try VlessSPM.decodeSubscriptionText(armor, ageSecretKey: "invalid")
        XCTAssertFalse(missingKey.success)
        XCTAssertFalse(invalidKey.success)
        XCTAssertNotEqual(missingKey.error, invalidKey.error)

        let converted = try VlessSPM.convertShareLinks(link, dataType: Config.self)
        XCTAssertTrue(converted.success, converted.error ?? "")
        XCTAssertEqual(converted.data?.outbounds.first?.protocol, "vless")
        XCTAssertEqual(converted.data?.outbounds.first?.tag, "Example")

        let invalid = try VlessSPM.convertShareLinks("not a link", dataType: Config.self)
        XCTAssertFalse(invalid.success)
        XCTAssertNil(invalid.data)
        XCTAssertFalse(invalid.error?.isEmpty ?? true)
        let invalidAge = try VlessSPM.convertShareLinks(armor, ageSecretKey: "invalid", dataType: Config.self)
        XCTAssertFalse(invalidAge.success)
        XCTAssertEqual(invalidAge.error, invalidKey.error)

        let json = #"{"outbounds":[{"protocol":"vless","tag":"Example","settings":{"vnext":[{"address":"example.com","port":443,"users":[{"id":"12345678-abcd-abcd-abcd-123456789abc","encryption":"none"}]}]}}]}"#
        let links = try VlessSPM.convertXrayJsonToShareLinks(json)
        XCTAssertTrue(links.success, links.error ?? "")
        XCTAssertTrue(links.data?.links.hasPrefix("vless://") ?? false)
        let invalidJSON = try VlessSPM.convertXrayJsonToShareLinks("invalid")
        XCTAssertFalse(invalidJSON.success)
        XCTAssertFalse(invalidJSON.error?.isEmpty ?? true)
    }

    func testPingBatchResults() throws {
        let listener = socket(AF_INET, SOCK_STREAM, 0)
        guard listener >= 0 else { throw POSIXError(.EIO) }
        defer { close(listener) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr = in_addr(s_addr: in_addr_t(INADDR_LOOPBACK).bigEndian)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(listener, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0, listen(listener, 1) == 0 else { throw POSIXError(.EIO) }
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(listener, $0, &length)
            }
        }
        guard named == 0 else { throw POSIXError(.EIO) }

        let server = DispatchGroup()
        server.enter()
        DispatchQueue.global().async {
            defer { server.leave() }
            var descriptor = pollfd(fd: listener, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 6000) > 0 else { return }
            let connection = accept(listener, nil, nil)
            guard connection >= 0 else { return }
            defer { close(connection) }
            var noSigPipe: Int32 = 1
            setsockopt(connection, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
            var readable = pollfd(fd: connection, events: Int16(POLLIN), revents: 0)
            guard poll(&readable, 1, 6000) > 0 else { return }
            var request = [UInt8](repeating: 0, count: 1024)
            guard recv(connection, &request, request.count, 0) > 0 else { return }
            let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            _ = response.withCString { send(connection, $0, response.utf8.count, 0) }
        }
        defer { XCTAssertEqual(server.wait(timeout: .now() + 13), .success) }

        let config = #"{"outbounds":[{"protocol":"freedom","tag":"direct"}]}"#
        let response = try VlessSPM.pingBatch(
            [PingBatchItem(xrayJson: config), PingBatchItem(xrayJson: "invalid")],
            timeout: 3,
            url: "http://127.0.0.1:\(UInt16(bigEndian: address.sin_port))/"
        )
        XCTAssertEqual(server.wait(timeout: .now() + 7), .success)
        XCTAssertTrue(response.success, response.error ?? "")
        let results = try XCTUnwrap(response.data?.results)
        guard results.count == 2 else {
            XCTFail("Expected two ping results, got \(results.count)")
            return
        }
        XCTAssertTrue(results[0].success, results[0].error ?? "")
        XCTAssertGreaterThanOrEqual(results[0].delay, 0)
        XCTAssertFalse(results[1].success)
        XCTAssertFalse(results[1].error?.isEmpty ?? true)
    }
}
