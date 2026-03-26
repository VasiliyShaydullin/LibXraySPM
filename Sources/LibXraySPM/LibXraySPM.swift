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

public struct СheckRequest: Codable {
    public var datDir: String?
    public var configPath: String?
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
    
    private static func serialization(dataBase64: Data) throws -> [String: Any] {
        
        guard let decodedString = String(data: dataBase64, encoding: .utf8) else {
            throw DecodeError.customError("Failed to decode Base64 data into a valid UTF-8 string.")
        }
        
        guard let jsonData = decodedString.data(using: .utf8) else {
            throw DecodeError.customError("Failed to convert decoded string to JSON data.")
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let jsonDict = jsonObject as? [String: Any] else {
            throw DecodeError.customError("Failed to parse JSON object from data.")
        }
        
        guard let success = jsonDict["success"] as? Int else {
            throw DecodeError.customError("Missing or invalid 'success' field in the JSON object.")
        }
        
        guard success == 1 else {
            if let error = jsonDict["error"] as? String {
                throw DecodeError.customError("Operation failed with error: \(error)")
            }
            throw DecodeError.customError("Operation failed with unknown error.")
        }
        
        guard let dataValue = jsonDict["data"] else {
            throw DecodeError.customError("Missing 'data' field in the JSON object.")
        }
        
        guard let dataString = dataValue as? String else {
            throw DecodeError.customError("Field 'data' is not a valid string.")
        }
        
        guard let nestedJsonData = dataString.data(using: .utf8) else {
            throw DecodeError.customError("Failed to convert 'data' string to JSON data.")
        }
        
        guard let dataDict = try? JSONSerialization.jsonObject(with: nestedJsonData, options: []),
              let finalDict = dataDict as? [String: Any] else {
            throw DecodeError.customError("Failed to parse nested JSON object from 'data'.")
        }
        
        return finalDict
    }
    
    private static func serialization(stringBase64: String) throws -> [String: Any] {
        guard let base64Data = Data(base64Encoded: stringBase64) else {
            throw DecodeError.unknownError
        }
        guard let decodedString = String(data: base64Data, encoding: .utf8) else {
            throw DecodeError.customError("Failed to decode Base64 data into a valid UTF-8 string.")
        }
        
        guard let jsonData = decodedString.data(using: .utf8) else {
            throw DecodeError.customError("Failed to convert decoded string to JSON data.")
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let jsonDict = jsonObject as? [String: Any] else {
            throw DecodeError.customError("Failed to parse JSON object from data.")
        }
        return jsonDict
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
    
//    // MARK: - Convert Config
//    
//    public static func convertLinksToXrayJson(_ config: String) -> String {
//        return LibXrayConvertShareLinksToXrayJson(config)
//    }
    
    // MARK: - Xray Version
    
    public static func version() throws -> CallResponse<String> {
        let data = LibXrayXrayVersion()
        return try decodeResult(encodedString: data, dataType: String.self)
    }
    
    // MARK: - Query Stats
    
    public static func stats(_ base64TrafficString: String) throws -> [String: Any] {
        let data = LibXrayQueryStats(base64TrafficString)
        guard let base64Data = Data(base64Encoded: data) else {
            throw DecodeError.unknownError
        }
        return try serialization(dataBase64: base64Data)
    }
    
    // MARK: - Test Configuration
    
    public static func isValidConfig(datDir: String?, configPath: String?) throws -> Bool {
        let result: [String: Any] = try checkConfig(datDir: datDir, configPath: configPath)
        guard let success = result["success"] as? Int else {
            throw DecodeError.customError("Missing or invalid 'success' field in the JSON object.")
        }
        if success == 1 {
            return true
        } else if let error = result["error"] as? String {
            throw DecodeError.customError("Operation failed with error: \(error)")
        } else {
            throw DecodeError.customError("Operation failed with unknown error.")
        }
    }
    
    public static func checkConfig(datDir: String?, configPath: String?) throws -> [String: Any] {
        let data: String = try checkConfiguration(datDir: datDir, configPath: configPath)
        
        return try serialization(stringBase64: data)
    }
    
    public static func checkConfiguration(datDir: String?, configPath: String?) throws -> String {
        let config = СheckRequest(datDir: datDir, configPath: configPath)
        return try checkConfiguration(config)
    }
    
    public static func checkConfiguration(_ config: СheckRequest) throws -> String {
        let jsonData = try JSONEncoder().encode(config)
        let base64String = jsonData.base64EncodedString()
        let result = LibXrayTestXray(base64String)
        return result
    }
    
    // MARK: - Convert Share Links To XrayJson
    
    public static func convertShareLinkToString(_ link: String) throws -> String {
        let result = try convertShareLink(link)
        if result.success == true, let strJson = result.data {
            return strJson
        } else if let error = result.error {
            throw DecodeError.customError(error)
        }
        throw DecodeError.customError("Operation failed with unknown error.")
    }
    
    public static func convertShareLink(_ link: String) throws -> CallResponse<String> {
        
        let resultDic = try convertShareLinkToDic(link)
        if (resultDic["success"] as? Int) == 1, let data = resultDic["data"] {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            guard let strJson = String(data: jsonData, encoding: .utf8) else {
                throw DecodeError.customError("Failed to decode JSON data into a UTF-8 string.")
            }
            return CallResponse<String>(success: true, data: strJson, error: nil)
        } else if (resultDic["success"] as? Int) != 1, let error = resultDic["error"] as? String {
            return CallResponse<String>(success: false, data: nil, error: error)
        } else {
            throw DecodeError.customError("Operation failed with unknown error.")
        }
        
//        guard let linkData = link.data(using: .utf8) else {
//            throw DecodeError.customError("Invalid configuration string")
//        }
//        let base64EncodedConfig = linkData.base64EncodedString()
//        let xrayJsonString = LibXrayConvertShareLinksToXrayJson(base64EncodedConfig)
//        return try decodeResult(encodedString: xrayJsonString, dataType: String.self)
    }
    
    public static func convertShareLinkToDic(_ link: String) throws -> [String: Any] {
        guard let linkData = link.data(using: .utf8) else {
            throw DecodeError.customError("Invalid configuration string")
        }
        let base64EncodedConfig = linkData.base64EncodedString()
        let xrayJsonString = LibXrayConvertShareLinksToXrayJson(base64EncodedConfig)
        
        return try serialization(stringBase64: xrayJsonString)
    }
    
    // MARK: - Convert XrayJson To Share Links
    
    public static func convertXrayJsonToLink(_ config: String) throws -> String {
        let result: CallResponse<String> = try convertXrayJson(config)
        if result.success == true, let link = result.data {
            return link
        } else if let error = result.error {
            throw DecodeError.customError(error)
        }
        throw DecodeError.customError("Operation failed with unknown error.")
    }
    
    public static func convertXrayJson(_ config: String) throws -> CallResponse<String> {
        guard let configData = config.data(using: .utf8) else {
            throw DecodeError.customError("Invalid configuration")
        }
        let base64EncodedConfig = configData.base64EncodedString()
        let stringBase64 = LibXrayConvertXrayJsonToShareLinks(base64EncodedConfig)
        
        return try decodeResult(encodedString: stringBase64, dataType: String.self)
    }
    
    public static func convertXrayJson(_ config: String) throws -> String {
        guard let configData = config.data(using: .utf8) else {
            throw DecodeError.customError("Invalid configuration")
        }
        let base64EncodedConfig = configData.base64EncodedString()
        let stringBase64 = LibXrayConvertXrayJsonToShareLinks(base64EncodedConfig)
        
        guard let base64Data = Data(base64Encoded: stringBase64) else {
            throw DecodeError.unknownError
        }
        guard let decodedString = String(data: base64Data, encoding: .utf8) else {
            throw DecodeError.customError("Failed to decode Base64 data into a valid UTF-8 string.")
        }
        return decodedString
    }
}
