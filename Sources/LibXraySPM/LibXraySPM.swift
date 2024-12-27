import Foundation
import LibXray

public struct RunXrayRequest: Codable {
    public var datDir: String?
    public var configPath: String?
    public var maxMemory: Int64?
}

public struct CallResponse<T: Decodable>: Decodable {
    public let success: Bool
    public var data: T?
    public let error: String?
}

public enum DecodeError: Error, LocalizedError {
    case invalidBase64
    case customError(String)
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "The provided string is not a valid Base64 encoded string."
        case .customError(let message):
            return message
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

public struct PingRequest: Codable {
    public var datDir: String?
    public var configPath: String?
    public var timeout: Int?
    public var url: String?
    public var proxy: String?
    
    public init(datDir: String?, configPath: String?, timeout: Int?, url: String?, proxy: String?) {
        self.datDir = datDir
        self.configPath = configPath
        self.timeout = timeout
        self.url = url
        self.proxy = proxy
    }
}


public struct LibXraySPM {
    
    // MARK: - Run
    
    public static func run(datDir: String?, configPath: String?, maxMemory: Int64?) throws -> String {
        let config = RunXrayRequest(datDir: datDir, configPath: configPath, maxMemory: maxMemory)
        return try run(config)
    }
    
    public static func run(_ config: RunXrayRequest) throws -> String {
        let jsonData = try JSONEncoder().encode(config)
        let base64String = jsonData.base64EncodedString()
        let result = LibXrayRunXray(base64String)
        return result
    }
    
    public static func run<T: Decodable>(datDir: String?, configPath: String?, maxMemory: Int64?, dataType: T.Type) throws -> CallResponse<T> {
        let config = RunXrayRequest(datDir: datDir, configPath: configPath, maxMemory: maxMemory)
        let response = try run(config)
        return try decodeResult(encodedString: response, dataType: T.self)
    }
    
    public static func run<T: Decodable>(_ config: RunXrayRequest, dataType: T.Type) throws -> CallResponse<T> {
        let response = try run(config)
        return try decodeResult(encodedString: response, dataType: T.self)
    }
    
    // MARK: - Decode Result CallResponse
    
    private static func decodeResult<T: Decodable>(encodedString: String, dataType: T.Type) throws -> CallResponse<T> {
        guard let data = Data(base64Encoded: encodedString) else {
            throw DecodeError.invalidBase64
        }
        return try JSONDecoder().decode(CallResponse<T>.self, from: data)
//      ▿ CallResponse<String>
//        - success : true
//        - data : nil
//        - error : nil
    }
    
    // MARK: - Stop
    
    public static func stop() -> String {
        let result = LibXrayStopXray()
        return result
    }
    
    public static func stop<T: Decodable>(dataType: T.Type) throws -> CallResponse<T> {
        let response = stop()
        return try decodeResult(encodedString: response, dataType: T.self)
    }
    
    // MARK: - Ping
    
//    type pingRequest struct {
//        DatDir     string `json:"datDir,omitempty"`
//        ConfigPath string `json:"configPath,omitempty"`
//        Timeout    int    `json:"timeout,omitempty"`
//        Url        string `json:"url,omitempty"`
//        Proxy      string `json:"proxy,omitempty"`
//    }
    
    public static func ping(config: PingRequest) throws -> CallResponse<Int> {
        let data: String = try ping(config)
        return try decodeResult(encodedString: data, dataType: Int.self)
    }
    
    public static func ping(_ config: PingRequest) throws -> String {
        let jsonData = try JSONEncoder().encode(config)
        let base64String = jsonData.base64EncodedString()
        let result = LibXrayPing(base64String)
        return result
    }
    
    // MARK: - Get Free Ports
    
    public static func freePorts(_ count: Int) throws -> [Int] {
        let freePortsBase64String = LibXrayGetFreePorts(count)
        let result = try decodeResult(encodedString: freePortsBase64String, dataType: [String: [Int]].self)
        if result.success {
            return result.data?["ports"] ?? []
        }
        if let error = result.error {
            throw DecodeError.customError(error)
        }
        throw DecodeError.unknownError
    }
    
    // MARK: - Convert Config
    
    public static func convertLinksToXrayJson(_ config: String) -> String {
        return LibXrayConvertShareLinksToXrayJson(config)
    }
    
    // MARK: - Xray Version
    
    public static func version() throws -> CallResponse<String> {
        let data = LibXrayXrayVersion()
        return try decodeResult(encodedString: data, dataType: String.self)
    }
    
}
