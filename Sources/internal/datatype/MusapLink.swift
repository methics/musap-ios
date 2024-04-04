//
//  MusapLink.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 8.1.2024.
//

import Foundation

public class MusapLink: Encodable, Decodable {
    
    private static let COUPLE_MSG_TYPE       = "linkaccount"
    private static let ENROLL_MSG_TYPE       = "enrolldata"
    private static let POLL_MSG_TYPE         = "getdata"
    private static let SIG_CALLBACK_MSG_TYPE = "signaturecallback"
    private static let SIGN_MSG_TYPE         = "externalsignature"
    private static let KEY_CALLBACK_MSG_TYPE = "generatekeycallback"
    
    
    private static let POLL_AMOUNT = 20
    
    private let url:     String
    private var musapId: String?

    private static let encryption = AesTransportEncryption(keyStorage: KeychainKeystorage())
    private static let mac = HmacGenerator(keyStorage: KeychainKeystorage())
    
    public init(url: String, musapId: String?) {
        self.url = url
        self.musapId = musapId
    }
    
    public func setMusapId(musapId: String) {
        self.musapId = musapId
    }
    
    
    /**
     Enroll this MUSAP instance with MUSAP Link
        - Returns: MusapLink
        - Throws: MusapError
     */
    public func enroll(apnsToken: String?) async throws -> MusapLink {
        //TODO: These throws need to be made better
        var secret: String?
        
        do {
            secret = try MusapKeyGenerator.hkdfStatic()
            print("Secret: \(String(describing: secret))")
        } catch {
            print("Error creating secret: \(error)")
        }
        
        guard let secret = secret else {
            print("No secret")
            throw MusapError.internalError
        }
        
        let payload = EnrollDataPayload(apnstoken: apnsToken, secret: secret)
        guard let payload = payload.getBase64Encoded() else {
            throw MusapError.internalError
        }
        
        let msg = MusapMessage()
        msg.payload = payload
        msg.type = MusapLink.ENROLL_MSG_TYPE
        
        do {
            let musapMsg = try await self.sendRequest(msg, shouldEncrypt: true)
            
            print("payload: \(String(describing: musapMsg.payload))")
            guard let payload = musapMsg.payload,
                  let payloadData = payload.data(using: .utf8)
            else {
                // Payload was empty or couldnt turn string to Data()
                throw MusapError.internalError
            }
            
            let enrollDataResponsePayload = try JSONDecoder().decode(EnrollDataResponsePayload.self, from: payloadData)
            
            guard let musapId = enrollDataResponsePayload.musapid else {
                throw MusapError.internalError
            }
            
            print("Musap ID: \(musapId)")
            self.musapId = musapId
            return self
            
        } catch {
            print("Error in enroll(): \(error)")
            return self
        }
  
    }
    
    /**
     Couple this MUSAP with a MUSAP Link.
     This performs networking operations.
        - Parameters:
           - couplingCode: The coupling code
           - musapId: Musap ID
        - Returns: RelyingParty
     */
    public func couple(couplingCode: String, musapId: String) async throws -> RelyingParty {
        let payload = LinkAccountPayload(couplingcode: couplingCode, musapid: musapId)
        
        print("Payload MUSAP ID: \(payload.musapid)")
        
        guard let payloadB64 = payload.getBase64Encoded() else {
            print("Cant turn payload to Base64")
            throw MusapError.internalError
        }
        
        
        print("payload as B64: \(payloadB64)")
        let msg = MusapMessage()
        msg.type = MusapLink.COUPLE_MSG_TYPE
        msg.payload = payloadB64
        msg.musapid = musapId
        
        do {
            print("Trying to sendRequest...")
            let respMsg = try await self.sendRequest(msg, shouldEncrypt: true)
            
            guard let payload = respMsg.payload else {
                print("Could not get paylaod from respMsg")
                throw MusapError.internalError
            }
            
            guard let payloadData = payload.data(using: .utf8)
            else {
                print("Could not turn payload to Data()")
                throw MusapError.internalError
            }
            
            print("Making linkAccountResponsePayload from payloadData")
            let linkAccountResponsePayload = try JSONDecoder().decode(LinkAccountResponsePayload.self, from: payloadData)
            
            let linkId = linkAccountResponsePayload.linkid
            let rpName = linkAccountResponsePayload.name
            
            let relyingParty = RelyingParty(name: rpName, linkId: linkId)
            return relyingParty
            
        } catch {
            print("error in MusapLink.couple(): \(error)")
        }
        
        throw MusapError.internalError //TODO: MusapLink.couplingError or something
    }
    
    public func poll() async throws -> PollResponsePayload? {
        let msg = MusapMessage()
        msg.type = MusapLink.POLL_MSG_TYPE
        msg.musapid = self.musapId
        
        guard let url = URL(string: self.url) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(msg)
            request.httpBody = jsonData
            
            // To see from xcode what we are getting for debugging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("POLL request body: \(jsonString)")
            }
            
        } catch {
            print("error encoding json: \(error)")
        }

        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("poll: HTTP status code was not 200")
            throw MusapError.internalError
        }
        
        let decoder = JSONDecoder()
        let respMsg = try decoder.decode(MusapMessage.self, from: data)
        
        guard let payloadBase64 = respMsg.payload else {
            print("No payload in musap message")
            throw MusapError.internalError
        }
        
        print("Payload: \(payloadBase64)")
        
        guard let payloadData = Data(base64Encoded: payloadBase64) else {
            print("Cant turn payload to Data()")
            throw MusapError.internalError
        }
        
        do {
            print("trying to make SignaturePayload object from JSON")
            let signaturePayload = try decoder.decode(SignaturePayload.self, from: payloadData)
            
            print("Got the obj: \(signaturePayload.display)")
            guard let transId = respMsg.transid else {
                print("error in poll: no transId")
                throw MusapError.internalError
            }
            
            return PollResponsePayload(
                signaturePayload: signaturePayload,
                transId: transId,
                status: "success",
                errorCode: nil
            )
        } catch {
            print("error: \(error)")
        }
        
        return nil
        
    }
    
    public func sendKeygenCallback(key: MusapKey, txnId: String) throws {
        
        let payload = SignatureCallbackPayload(key: key)
        
        let msg = MusapMessage()
        msg.type = MusapLink.KEY_CALLBACK_MSG_TYPE
        msg.type = payload.getBase64Encoded()
        msg.musapid = self.musapId
        msg.transid = txnId
        
        guard let url = URL(string: self.url) else {
            print("NO URL")
            return
        }
        
        var jsonData: Data?
        let encoder = JSONEncoder()
        
        do {
            jsonData = try encoder.encode(msg)
        } catch {
            print("Could not turn MusapMessage to JSON")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
        
            if let error = error {
                return
            }
            
            guard let data = data,
                  let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                print("Null payload")
                return
            }
            print("sendKeygenCallback response payload: \(String(describing: responseMsg.payload))")
        }
        
        task.resume()
    }
    
    public func sendSignatureCallback(signature: MusapSignature, transId: String) throws {
        let payload = SignatureCallbackPayload(linkid: nil, signature: signature)
        payload.attestationResult = signature.getKeyAttestationResult()
        
        let msg = MusapMessage()
        msg.type = MusapLink.SIG_CALLBACK_MSG_TYPE
        msg.payload = payload.getBase64Encoded()
        msg.musapid = self.musapId
        msg.transid = transId
        
        guard let url = URL(string: self.url) else {
            print("NO URL")
            return
        }
        
        var jsonData: Data?
        let encoder = JSONEncoder()
        do {
            jsonData = try encoder.encode(msg)
        } catch {
            print("Could not turn MusapMessage to JSON")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("HTTP Request created")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("sendSignatureCallback error: \(error)")
                return
            }
            
            guard let data = data,
                  let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                print("Null payload")
                return
            }
            
            print("sendSignatureCallback response payload: \(String(describing: responseMsg.payload))")
            
        }
        task.resume()
    }
    
    public func sign(payload: ExternalSignaturePayload, completion: @escaping (Result<ExternalSignatureResponsePayload, Error>) -> Void) {
        guard let payloadBase64 = payload.getBase64Encoded() else {
            print("Could not get payload as base64")
            completion(.failure(MusapError.internalError))
            return
        }
        
        print("Sign payload: \(payloadBase64)")

        let msg = MusapMessage()
        msg.payload = payloadBase64
        msg.type = MusapLink.SIGN_MSG_TYPE
        msg.musapid = self.getMusapId()

        self.sendRequest(msg, shouldEncrypt: true) { respMsg, error in
            if let error = error {
                print("sendRequest had an error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let resp = respMsg else {
                print("No Resp message")
                return
            }
            
            print("RESP: \(resp)")
            
            // TODO: We have a problem: No payload
            guard let payload = resp.payload else {
                print("No payload in resp")
                return
            }
            
            print("payload: \(payload)")
            
            guard let payloadAsData = Data(base64Encoded: payload) else {
                print("Could not turn payload to Data")
                return
            }
            
            guard let respMsg = respMsg,
                  let payloadString = respMsg.payload,
                  let payloadData = Data(base64Encoded: payloadString) else {
                DispatchQueue.main.async {
                    print("no payload or cant turn payload to Data()")
                    completion(.failure(MusapError.internalError))
                }
                return
            }

            do {
                let resp = try JSONDecoder().decode(ExternalSignatureResponsePayload.self, from: payloadData)
                                
                DispatchQueue.main.async {
                    if resp.status == "pending" {
                        print("status: Pending")
                        self.pollForSignature(transId: resp.transid) { result in
                                
                            switch result {
                            case .success(let payload):
                                print("Debugging ExternalSignatureResponsePayload: \(payload.description)")
                                print("got payload of MusapLink.pollForSignature: \(payload.isSuccess())")
                                guard let signature = payload.signature,
                                      let signatureData = signature.data(using: .utf8)
                                else {
                                    completion(.failure(MusapError.internalError))
                                    return
                                }
                                
                                completion(.success(payload))
                            case .failure(let error):
                                print("Error: \(error)")
                                completion(.failure(error))
                            }
                            
                        }
                    } else if resp.status == "failed" {
                        print("status: Failed")
                        completion(.failure(MusapError.internalError))
                    } else {
                        completion(.success(resp))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("musapLink.sign(): \(error)")
                    completion(.failure(MusapError.internalError))
                }
            }
        }
    }
    
    //TODO: Every throw needs to be inspected for better options
    public func sendRequest(_ msg: MusapMessage, shouldEncrypt: Bool) async throws -> MusapMessage {
        guard let url = URL(string: self.url) else {
            print("Could not get URL")
            throw MusapError.internalError
        }
        
        guard let msgType = msg.type,
              let payload = msg.payload
        else {
            print("Msgtype or payload was nil")
            throw MusapError.internalError
        }
        
        if shouldEncrypt && msgType != MusapLink.ENROLL_MSG_TYPE {
            guard let payloadHolder = self.getPayload(payloadBase64: payload, shouldEncrypt: shouldEncrypt)
            else
            {
                throw MusapError.internalError
            }
            
            msg.payload = payloadHolder.getPayload()
            
            guard msg.payload != nil else {
                print("Could not get payload")
                throw MusapError.internalError
            }
            msg.iv = payloadHolder.getIv()
            
            print("sendRequest IV: \(String(describing: msg.iv))")
            
            do {
                msg.mac = try MusapLink.mac.generate(message: msg.payload ?? "", iv: msg.iv ?? "", transId: msg.getIdentifier(), type: msgType)

            } catch {
                print("Failed to generate mac")
                throw MusapError.internalError
            }
        }
        
        guard let jsonData = try? JSONEncoder().encode(msg) else {
            print("Could not turn MusapMessage to JSON")
            throw MusapError.internalError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        print("Sending request...")
        
        let (data, _) = try await URLSession.shared.data(for: request)

        guard !data.isEmpty else {
            print("Data was empty")
            throw MusapError.internalError
        }
        
        print("trying to decode json from data")
        let responseMsg = try JSONDecoder().decode(MusapMessage.self, from: data)
        
        print("Parsing payload")
        responseMsg.payload = self.parsePayload(respMsg: responseMsg, isEncrypted: shouldEncrypt)

        return responseMsg
    }

    
    public func sendRequest(_ msg: MusapMessage, shouldEncrypt: Bool, completion: @escaping (MusapMessage?, Error?) -> Void) {

        print("ShouldEncrypt: \(shouldEncrypt)")
        debugPrint("msg payload: \(String(describing: msg.payload))")
        
        guard let msgType = msg.type,
              let payload = msg.payload
        else {
            print("No msg type or payload defined")
            completion(nil, MusapError.internalError)
            return
        }
        
        if shouldEncrypt && msgType != MusapLink.ENROLL_MSG_TYPE {
            print("Encrypting message")
            
            guard let holder = self.getPayload(payloadBase64: payload, shouldEncrypt: shouldEncrypt)
            else 
            {
                print("Could not get PayloadHolder or IV")
                completion(nil, MusapError.internalError)
                return
            }
            
            msg.payload = holder.getPayload()
            msg.iv = holder.getIv()
        
            do {
                msg.mac = try MusapLink.mac.generate(message: payload, iv: msg.iv ?? "", transId: msg.transid, type: msgType)

            } catch {
                print("error: \(error)")
            }
        }
        
        guard let jsonData = try? JSONEncoder().encode(msg) else {
            print("MusapLink.sendRequest(): Could not turn MusapMessage to JsonData")
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message"]))
            return
        }
        
        print("sendRequest: JSON STRING OF REQUEST: \(jsonData.base64EncodedString())")
        
        guard let url = URL(string: self.url) else {
            print("MUsapLink.sendRequest(): No URL")
            completion(nil, MusapError.internalError)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error in URLSession: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data,
                  !data.isEmpty
            else 
            {
                print("sendRequest: No data")
                completion(nil, nil)
                return
            }
            
            print("sendRequest Data: \(data.base64EncodedString())")
            
            guard let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                print("Failed to parse json to MusapMessage")
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                return
            }
            
            responseMsg.payload = self.parsePayload(respMsg: responseMsg, isEncrypted: shouldEncrypt)
            print("We completed sendRequest()")
            completion(responseMsg, nil)
        }

        task.resume()
    }
    
    
    private func pollForSignature(transId: String, completion: @escaping (Result<ExternalSignatureResponsePayload, Error>) -> Void) {
        print("Polling for signature")
        
        var isPollingDone = false
        
        for i in 0..<MusapLink.POLL_AMOUNT {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2 * i)) {
                guard !isPollingDone else { return }
                
                self.performPollIteration(transId: transId) { result in
                
                    switch result {
                    case .failure:
                        isPollingDone = true
                        DispatchQueue.main.async {
                            completion(.failure(MusapError.internalError))
                        }
                    case .success(let response):
                        isPollingDone = true
                        DispatchQueue.main.async {
                            completion(.success(response))
                        }
                    case .keepPolling:
                        break
                    }
                    
                }
            }
        }
    }
    
    public func getMusapId() -> String? {
        return self.musapId
    }
    
    private enum PollIterationResult {
        case success(ExternalSignatureResponsePayload)
        case failure
        case keepPolling
    }
    
    private func performPollIteration(transId: String, completion: @escaping (PollIterationResult) -> Void) {
        let payload = ExternalSignaturePayload()
        payload.transid = transId
        
        guard let payloadBase64 = payload.getBase64Encoded() else {
            completion(.failure)
            return
        }
        
        let musapMsg = MusapMessage()
        musapMsg.payload = payloadBase64
        musapMsg.type    = MusapLink.SIGN_MSG_TYPE
        musapMsg.musapid = self.getMusapId()
        
        self.sendRequest(musapMsg, shouldEncrypt: true) { respMsg, error in
            if let error = error {
                print("MusapLink.pollForSignature: Error in the link response - \(error.localizedDescription)")
                completion(.failure)
                return
            }
            
            guard let respMsg = respMsg else {
                print("sendRequest: No data or empty response")
                completion(.keepPolling)
                return
            }
            
            guard let msgPayload = respMsg.payload,
                  let payloadData = Data(base64Encoded: msgPayload) else {
                completion(.failure)
                return
            }
            
            if let resp = try? JSONDecoder().decode(ExternalSignatureResponsePayload.self, from: payloadData) {
                if resp.status == "pending" {
                    print("Status is pending")
                    completion(.keepPolling)
                } else if resp.status == "failed" {
                    print("Status was marked as failed")
                    completion(.failure)
                } else {
                    print("Returning success")
                    completion(.success(resp))
                }
            } else {
                completion(.failure)
            }
            
        }
        
    }
    
    private func getPayload(payloadBase64: String, shouldEncrypt: Bool) -> PayloadHolder? {
        print("Getting payload")
        if shouldEncrypt {
            guard let payloadHolder = MusapLink.encryption.encrypt(message: payloadBase64) else {
                print("Could not encrypt payloadBase64")
                return nil
            }
            return payloadHolder
        }

        return PayloadHolder(payload: payloadBase64, iv: nil)
    }
    
    public func parsePayload(respMsg: MusapMessage, isEncrypted: Bool) -> String? {
        
        if isEncrypted {
            
            guard let payload = respMsg.payload else {
                print("No payload, cant parse")
                return nil
            }
            
            guard let decodedPayload = Data(base64Encoded: payload) else {
                print("Cant turn payload to Data from base64encoded string")
                return nil
            }
            
            guard let iv = respMsg.iv else {
                print("No IV in parsePayload")
                return nil
            }
            
            let decrypted = MusapLink.encryption.decrypt(message: decodedPayload, iv: iv)
            print("Decrypted payload: \(String(describing: decrypted))")
            return decrypted
        }
        
        guard let message = respMsg.payload,
              let data = Data(base64Encoded: message)
        else {
            return nil
        }
        
        let decodedString = String(data: data, encoding: .utf8)
        print("Decoded: \(String(describing: decodedString))")
        
        return decodedString
    }
    
    private func isMacValid(msg: MusapMessage) -> Bool {
        print("Validating MAC")
        
        guard let payload = msg.payload,
              let iv = msg.iv,
              let transid = msg.transid,
              let type = msg.type,
              let mac = msg.mac 
        else {
            print("One of missing: Payload, iv, transid, type, mac")
            return false
        }
        
        do {
            return try MusapLink.mac.validate(message: payload, iv: iv, transId: transid, type: type, mac: mac)
        } catch {
            return false
        }
        
    }
    
    public func updateApnsToken(apnsToken: String) -> Bool {
        //TODO: Implement this
        return false
    }
    
}
