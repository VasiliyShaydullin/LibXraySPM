import Foundation
import LibXray

public struct CallResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let error: String?
}

extension CallResponse: Sendable where T: Sendable {}

public enum LibXrayError: Error, LocalizedError {
    case invalidRequest
    case invalidRequestEncoding
    case noResponse
    case invalidResponse
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The request contains a null character."
        case .invalidRequestEncoding:
            return "The encoded request is not valid UTF-8."
        case .noResponse:
            return "libXray returned no response."
        case .invalidResponse:
            return "libXray returned an invalid response."
        case .operationFailed(let message):
            return message
        }
    }
}

public struct EmptyPayload: Encodable, Sendable {
    public init() {}
}

public struct EmptyResponse: Decodable, Sendable {}

public struct XrayVersion: Decodable, Sendable {
    public let version: String
}

public struct XrayState: Decodable, Sendable {
    public let running: Bool
}

public struct SubscriptionText: Decodable, Sendable {
    public let text: String
}

public struct ShareLinks: Decodable, Sendable {
    public let links: String
}

public struct PingBatchItem: Encodable, Sendable {
    public let xrayJson: String
    public let outboundTag: String?

    public init(xrayJson: String, outboundTag: String? = nil) {
        self.xrayJson = xrayJson
        self.outboundTag = outboundTag
    }
}

public struct PingBatchResult: Decodable, Sendable {
    public let success: Bool
    public let delay: Int64
    public let error: String?
}

public struct PingBatchResponse: Decodable, Sendable {
    public let results: [PingBatchResult]?
}

private struct InvokeRequest<Payload: Encodable>: Encodable {
    let apiVersion = 3
    let method: String
    let payload: Payload
}

private struct XrayPayload: Encodable {
    let xrayJson: String
}

private struct FreePortsPayload: Encodable {
    let count: Int
    let excludePorts: [Int]
}

private struct FreePortsResponse: Decodable {
    let ports: [Int]?
}

private struct PingBatchPayload: Encodable {
    let configs: [PingBatchItem]
    let timeout: Int
    let url: String
}

private struct AgeDecryptConfig: Encodable {
    let secretKey: String
}

private struct TextPayload: Encodable {
    let text: String
    let age: AgeDecryptConfig?
}

public struct LibXraySPM {
    public static func invoke(_ requestJSON: String) throws -> String {
        guard !requestJSON.utf8.contains(0) else {
            throw LibXrayError.invalidRequest
        }
        return try requestJSON.withCString { request in
            guard let response = CGoInvoke(UnsafeMutablePointer(mutating: request)) else {
                throw LibXrayError.noResponse
            }
            defer { CGoFree(response) }
            guard let result = String(validatingCString: response) else {
                throw LibXrayError.invalidResponse
            }
            return result
        }
    }

    public static func invoke<Payload: Encodable, Result: Decodable>(
        method: String,
        payload: Payload,
        dataType: Result.Type
    ) throws -> CallResponse<Result> {
        let request = InvokeRequest(method: method, payload: payload)
        let data = try JSONEncoder().encode(request)
        guard let json = String(data: data, encoding: .utf8) else {
            throw LibXrayError.invalidRequestEncoding
        }
        let response = try invoke(json)
        return try JSONDecoder().decode(CallResponse<Result>.self, from: Data(response.utf8))
    }

    public static func run(xrayJson: String) throws -> CallResponse<EmptyResponse> {
        try invoke(method: "runXray", payload: XrayPayload(xrayJson: xrayJson), dataType: EmptyResponse.self)
    }

    public static func stop() throws -> CallResponse<EmptyResponse> {
        try invoke(method: "stopXray", payload: EmptyPayload(), dataType: EmptyResponse.self)
    }

    public static func test(xrayJson: String) throws -> CallResponse<EmptyResponse> {
        try invoke(method: "testXray", payload: XrayPayload(xrayJson: xrayJson), dataType: EmptyResponse.self)
    }

    public static func version() throws -> CallResponse<XrayVersion> {
        try invoke(method: "xrayVersion", payload: EmptyPayload(), dataType: XrayVersion.self)
    }

    public static func state() throws -> CallResponse<XrayState> {
        try invoke(method: "getXrayState", payload: EmptyPayload(), dataType: XrayState.self)
    }

    public static func freePorts(_ count: Int, excluding ports: [Int] = []) throws -> [Int] {
        let response = try invoke(
            method: "getFreePorts",
            payload: FreePortsPayload(count: count, excludePorts: ports),
            dataType: FreePortsResponse.self
        )
        guard response.success, let data = response.data else {
            throw LibXrayError.operationFailed(response.error ?? "Missing free ports response.")
        }
        if let result = data.ports {
            return result
        }
        guard count == 0 else {
            throw LibXrayError.invalidResponse
        }
        return []
    }

    public static func pingBatch(
        _ configs: [PingBatchItem],
        timeout: Int,
        url: String
    ) throws -> CallResponse<PingBatchResponse> {
        try invoke(
            method: "pingBatch",
            payload: PingBatchPayload(configs: configs, timeout: timeout, url: url),
            dataType: PingBatchResponse.self
        )
    }

    public static func decodeSubscriptionText(
        _ text: String,
        ageSecretKey: String? = nil
    ) throws -> CallResponse<SubscriptionText> {
        try invoke(
            method: "decodeSubscriptionText",
            payload: TextPayload(text: text, age: ageSecretKey.map { AgeDecryptConfig(secretKey: $0) }),
            dataType: SubscriptionText.self
        )
    }

    public static func convertShareLinks<Result: Decodable>(
        _ text: String,
        ageSecretKey: String? = nil,
        dataType: Result.Type
    ) throws -> CallResponse<Result> {
        try invoke(
            method: "convertShareLinksToXrayJson",
            payload: TextPayload(text: text, age: ageSecretKey.map { AgeDecryptConfig(secretKey: $0) }),
            dataType: dataType
        )
    }

    public static func convertXrayJsonToShareLinks(
        _ xrayJson: String
    ) throws -> CallResponse<ShareLinks> {
        try invoke(
            method: "convertXrayJsonToShareLinks",
            payload: XrayPayload(xrayJson: xrayJson),
            dataType: ShareLinks.self
        )
    }
}

public typealias VlessSPM = LibXraySPM
