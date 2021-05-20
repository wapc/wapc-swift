import Foundation
import WasmInterpreter
//
//enum WapcFunctions: String {
//    case guestResponse = "__guest_response"
//    case guestError = "__guest_error"
//    case hostCall = "__host_call"
//    case hostResponseLen = "__host_response_len"
//    case hostResponse = "__host_response"
//    case hostErrorLen = "__host_error_len"
//    case hostError = "__host_error"
//    case consoleLog = "__console_log"
//}

public struct WapcHost {
    private let _vm: WasmInterpreter
    private var _state: ModuleState
    private let HOST_NS = "wapc"

    init(module: [UInt8]) throws {
        _vm = try WasmInterpreter(stackSize: 1 * 120 * 1024, module: module)
        _state = ModuleState()
        
        try _vm.addImportHandler(named: "__guest_response", namespace: HOST_NS, block: self.__guest_response)
        try _vm.addImportHandler(named: "__guest_error", namespace: HOST_NS, block: self.__guest_error)
        try _vm.addImportHandler(named: "__host_call", namespace: HOST_NS, block: self.__host_call)
        try _vm.addImportHandler(named: "__host_response_len", namespace: HOST_NS, block: self.__host_response_len)
        try _vm.addImportHandler(named: "__host_response", namespace: HOST_NS, block: self.__host_response)
        try _vm.addImportHandler(named: "__host_error_len", namespace: HOST_NS, block: self.__host_error_len)
        try _vm.addImportHandler(named: "__host_error", namespace: HOST_NS, block: self.__host_error)
        try _vm.addImportHandler(named: "__console_log", namespace: HOST_NS, block: self.__console_log)
        
//        print("Finished init successfully")
    }

    private func __guest_request(opPtr: Int32, ptr: Int32) throws -> Void {
        if let inv = self._state.getGuestRequest() {
            try self._vm.writeToHeap(string: inv.op, byteOffset: Int(opPtr))
            try self._vm.writeToHeap(bytes: inv.msg, byteOffset: Int(ptr))
        } else {
            print("No invocation registered")
        }
    }
    
    private func __guest_error(ptr: Int32, len: Int32) throws -> Void {
        let error = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let string = String(bytes: error, encoding: .utf8) {
            print("Guest error: ", string)
        } else {
            print("Failed to deserialize guest error, not utf8 bytes")
        }
    }
    
    private func __guest_response(ptr: Int32, len: Int32) throws -> Void {
        print("Guest response invoked")
    }
    
    private func __host_call(bdPtr: Int32, bdLen: Int32, nsPtr: Int32, nsLen: Int32, opPtr: Int32, opLen: Int32, ptr: Int32, len: Int32) throws -> Int32 {
        //TODO: implement this https://github.com/wapc/wapc-rust/blob/master/src/lib.rs#L247
        let binding = try self._vm.bytesFromHeap(byteOffset: Int(bdPtr), length: Int(bdLen))
        let namespace = try self._vm.bytesFromHeap(byteOffset: Int(nsPtr), length: Int(nsLen))
        let operation = try self._vm.bytesFromHeap(byteOffset: Int(opPtr), length: Int(opLen))
        let body = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let bd = String(bytes: binding, encoding: .utf8), let ns = String(bytes: namespace, encoding: .utf8), let op = String(bytes: operation, encoding: .utf8), let vec = String(bytes: body, encoding: .utf8) {
            print(String(format: "Guest invoked '%@->%@:%@ with a payload of %@'", bd, ns, op, vec))
        } else {
            print("Failed to deserialize host call arguments")
        }
        
        return -1
    }
    
    private func __host_response(ptr: Int32) throws {
        //print("Host response")
    }
    
    private func __host_response_len() throws -> Int32 {
        //print("Host response len")
        return -1
    }
    
    private func __host_error(ptr: Int32) throws {
        //print("Host error")
        if let err = self._state.getHostError() {
            try self._vm.writeToHeap(string: err, byteOffset: Int(ptr))
        } else {
            print("No host error, not writing to heap")
        }
    }
    
    private func __host_error_len() throws -> Int32 {
        //print("Host error len invoked")
        if let err = self._state.getHostError() {
            return Int32(err.count)
        } else {
            return 0
        }
    }
    
    private func __console_log(ptr: Int32, len: Int32) throws {
        let logBytes = try self._vm.bytesFromHeap(byteOffset: Int(ptr), length: Int(len))
        if let log = String(bytes: logBytes, encoding: .utf8) {
            print("Guest logged: ", log)
        } else {
            print("Failed to deserialize guest error, not utf8 bytes")
        }
    }

    mutating func __guest_call(op: String, bd: [UInt8]) throws -> Int {
        self._state.setGuestRequest(inv: Invocation(op: op, msg: bd))
        // Add the `__guest_request` operation here as it creates a closure around the state
        try _vm.addImportHandler(named: "__guest_request", namespace: HOST_NS, block: self.__guest_request)
        try _vm.call("__guest_call", Int32(op.count), Int32(bd.count))
        return 1
    }

}

struct Invocation {
    var op: String
    var msg: [UInt8]
    
    init(op: String, msg: [UInt8]) {
        self.op = op
        self.msg = msg
    }
}

struct ModuleState {
    private var guestRequest: Invocation?
    private var guestResponse: [UInt8]?
    private var hostResponse: [UInt8]?
    private var hostError: String?
    
    func getGuestRequest() -> Invocation? {
        return self.guestRequest
    }
    
    mutating func setGuestRequest(inv: Invocation) {
        self.guestRequest = inv
    }
    
    func getHostResponse() -> [UInt8]? {
        return self.hostResponse
    }
    
    mutating func setHostResponse(response: [UInt8]) {
        self.hostResponse = response
    }
    
    func getHostError() -> String? {
        return self.hostError
    }
    
    mutating func setHostError(error: String) {
        self.hostError = error
    }
}
