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
        AppLogger.shared.log("Trying to enroll. APNs token: \(apnsToken ?? "nil")")
        
        var secret: String?
        
        do {
            secret = try MusapKeyGenerator.hkdfStatic()
            AppLogger.shared.log("Transport secret: \(String(describing: secret))", .debug)
        } catch {
            AppLogger.shared.log("Error creating secret: \(error)", .error)
        }
        
        guard let secret = secret else {
            throw MusapError.internalError
        }
        
        let payload = EnrollDataPayload(apnstoken: apnsToken, secret: secret)
        guard let payload = payload.getBase64Encoded() else {
            AppLogger.shared.log("Failed to get BASE64 encoded payload. Unable to enroll", .error)
            throw MusapError.internalError
        }
        
        let msg = MusapMessage()
        msg.payload = payload
        msg.type = MusapLink.ENROLL_MSG_TYPE
        
        do {
            let musapMsg = try await self.sendRequest(msg, shouldEncrypt: true)
        
            AppLogger.shared.log("Payload: \(String(describing: musapMsg.payload))")
        
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
            
            AppLogger.shared.log("Found MUSAP ID: \(musapId)")
            
            self.musapId = musapId
            return self
        } catch {
            AppLogger.shared.log("Failed to enroll: \(error)")
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
        AppLogger.shared.log("Trying to couple...")
        
        let payload = LinkAccountPayload(couplingcode: couplingCode, musapid: musapId)
        
        AppLogger.shared.log("MUSAP ID is: \(payload.musapid)")
        
        guard let payloadB64 = payload.getBase64Encoded() else {
            AppLogger.shared.log("Failed to couple, unable to get base64 encoded payload", .error)
            throw MusapError.internalError
        }
        
        AppLogger.shared.log("Payload: \(payloadB64)")
        
        let msg = MusapMessage()
        msg.type = MusapLink.COUPLE_MSG_TYPE
        msg.payload = payloadB64
        msg.musapid = musapId
        
        do {
            AppLogger.shared.log("Trying to send HTTP request to couple")
            let respMsg = try await self.sendRequest(msg, shouldEncrypt: true)
            
            guard let payload = respMsg.payload else {
                AppLogger.shared.log("Failed to couple - could not find payload in response", .error)
                throw MusapError.internalError
            }
        
            AppLogger.shared.log("Coupling resp payload: \(payload)")
        
            guard let payloadData = payload.data(using: .utf8)
            else {
                AppLogger.shared.log("Failed to couple - could not turn payload to Data()", .error)
                throw MusapError.internalError
            }
            
            AppLogger.shared.log("Generating LinkAccountResponsePayload from payloadData")
            let linkAccountResponsePayload = try JSONDecoder().decode(LinkAccountResponsePayload.self, from: payloadData)
            
            let linkId = linkAccountResponsePayload.linkid
            let rpName = linkAccountResponsePayload.name
            
            let relyingParty = RelyingParty(name: rpName, linkId: linkId)
            return relyingParty
        } catch {
            AppLogger.shared.log("Failed to enroll with MUSAP Link: \(error)")
        }
        
        throw MusapError.internalError
    }
    
    public func poll() async throws -> PollResponsePayload? {
        AppLogger.shared.log("Trying to poll...", .debug)
        
        let msg = MusapMessage()
        msg.type = MusapLink.POLL_MSG_TYPE
        msg.musapid = self.musapId
        
        guard let url = URL(string: self.url) else {
            AppLogger.shared.log("Poll failed, invalid URL")
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
                AppLogger.shared.log("POLL request body: \(jsonString)", .debug)
            }
            
        } catch {
            AppLogger.shared.log("Error encoding to JSON: \(error)", .error)
        }

        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            AppLogger.shared.log("Polling failed, invalid HTTP status code", .error)
            throw MusapError.internalError
        }
        
        let decoder = JSONDecoder()
        let respMsg = try decoder.decode(MusapMessage.self, from: data)
        
        guard let payloadBase64 = respMsg.payload else {
            AppLogger.shared.log("No payload in MusapMessage, polling failed", .error)
            throw MusapError.internalError
        }
        
        AppLogger.shared.log("MusapMessage payload: \(payloadBase64)")
        
        guard let payloadData = Data(base64Encoded: payloadBase64) else {
            AppLogger.shared.log("Cant turn b64 payload to Data()", .error)
            throw MusapError.internalError
        }
        
        do {
            AppLogger.shared.log("Try to decode SignaturePayload object")
            let signaturePayload = try decoder.decode(SignaturePayload.self, from: payloadData)
            
            AppLogger.shared.log("Got the obj: \(signaturePayload.display)")
            guard let transId = respMsg.transid else {
                AppLogger.shared.log("Error in polling, no transaction ID found", .error)
                throw MusapError.internalError
            }
            
            return PollResponsePayload(
                signaturePayload: signaturePayload,
                transId: transId,
                status: "success",
                errorCode: nil
            )
        } catch {
            AppLogger.shared.log("Polling failed: \(error)")
        }
        
        return nil
    }
    
    public func sendKeygenCallback(key: MusapKey, txnId: String) throws {
        AppLogger.shared.log("Trying to send keygen callback...")
        
        let payload = SignatureCallbackPayload(key: key)
        
        let msg = MusapMessage()
        msg.type = MusapLink.KEY_CALLBACK_MSG_TYPE
        msg.type = payload.getBase64Encoded()
        msg.musapid = self.musapId
        msg.transid = txnId
        
        guard let url = URL(string: self.url) else {
            AppLogger.shared.log("Error sending keygen callback, invalid URL", .error)
            return
        }
        
        var jsonData: Data?
        let encoder = JSONEncoder()
        
        do {
            jsonData = try encoder.encode(msg)
        } catch {
            AppLogger.shared.log("Could not turn MusapMessage to JSON", .error)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
        
            guard error == nil else {
                AppLogger.shared.log("Error sending keygen callback", .error)
                return
            }
            
            guard let data = data,
                  let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                AppLogger.shared.log("Unable to decode to JSON")
                return
            }
            
            AppLogger.shared.log("Payload: \(responseMsg.payload ?? "(empty)")")
        }
        
        task.resume()
    }
    
    public func sendSignatureCallback(signature: MusapSignature, transId: String) throws {
        AppLogger.shared.log("Trying to send signature callback...")
        
        let payload = SignatureCallbackPayload(linkid: nil, signature: signature)
        payload.attestationResult = signature.getKeyAttestationResult()
        
        let msg = MusapMessage()
        msg.type = MusapLink.SIG_CALLBACK_MSG_TYPE
        msg.payload = payload.getBase64Encoded()
        msg.musapid = self.musapId
        msg.transid = transId
        
        guard let url = URL(string: self.url) else {
            AppLogger.shared.log("Invalid URL", .error)
            return
        }
        
        var jsonData: Data?
        let encoder = JSONEncoder()
        do {
            jsonData = try encoder.encode(msg)
        } catch {
            AppLogger.shared.log("Could not turn MusapMessage to JSON")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLogger.shared.log("Send signature callback error: \(error)", .error)
                return
            }
            
            guard let data = data,
                  let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                AppLogger.shared.log("Payload was null", .error)
                return
            }
            
            AppLogger.shared.log("Payload: \(responseMsg.payload ?? "(empty)")")
        }
        task.resume()
    }
    
    public func sign(payload: ExternalSignaturePayload, completion: @escaping (Result<ExternalSignatureResponsePayload, Error>) -> Void) {
        guard let payloadBase64 = payload.getBase64Encoded() else {
            AppLogger.shared.log("Found no payload", .error)
            completion(.failure(MusapError.internalError))
            return
        }

        AppLogger.shared.log("Signing payload B64: \(payloadBase64)", .info)
        
        let msg = MusapMessage()
        msg.payload = payloadBase64
        msg.type = MusapLink.SIGN_MSG_TYPE
        msg.musapid = self.getMusapId()

        self.sendRequest(msg, shouldEncrypt: true) { respMsg, error in
            if let error = error {
                AppLogger.shared.log("Error: \(error)", .error)
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let resp = respMsg else {
                AppLogger.shared.log("Null response", .error)
                return
            }
            
            guard let payload = resp.payload else {
                AppLogger.shared.log("No payload in resp", .error)
                return
            }
            
            AppLogger.shared.log("Found payload in resp: \(payload)")
            
            guard let payloadAsData = payload.data(using: .utf8) else {
                AppLogger.shared.log("Could not turn payload to Data()", .error)
                return
            }
            
            guard let respMsg = respMsg,
                  let payloadString = respMsg.payload,
                  let payloadData = payloadString.data(using: .utf8) else {
                DispatchQueue.main.async {
                    AppLogger.shared.log("No payload or cant turn payload to Data()", .error)
                    completion(.failure(MusapError.internalError))
                }
                return
            }

            do {
                let resp = try JSONDecoder().decode(ExternalSignatureResponsePayload.self, from: payloadData)
                                
                DispatchQueue.main.async {
                    if resp.status == "pending" {
                        AppLogger.shared.log("Status: Pending...", .info)
                        self.pollForSignature(transId: resp.transid) { result in
                                
                            switch result {
                            case .success(let payload):
                                AppLogger.shared.log("Status: \(payload.status)", .info)
                                
                                guard let signature = payload.signature,
                                      let signatureData = signature.data(using: .utf8)
                                else {
                                    AppLogger.shared.log("Failed to decode signature", .error)
                                    completion(.failure(MusapError.internalError))
                                    return
                                }
                                
                                AppLogger.shared.log("Payload: \(payload.description)")
                                completion(.success(payload))
                            case .failure(let error):
                                AppLogger.shared.log("Error: \(error)", .error)
                                completion(.failure(error))
                            }
                            
                        }
                    } else if resp.status == "failed" {
                        AppLogger.shared.log("Failed to sign: \(resp.errorCode ?? "Unknown error")", .error)
                        completion(.failure(MusapError.internalError))
                    } else {
                        AppLogger.shared.log("Signing was a success!", .info)
                        completion(.success(resp))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    AppLogger.shared.log("Error in signing: \(error)", .error)
                    completion(.failure(MusapError.internalError))
                }
            }
        }
    }
    
    //TODO: Every throw needs to be inspected for better options
    public func sendRequest(_ msg: MusapMessage, shouldEncrypt: Bool) async throws -> MusapMessage {
        guard let url = URL(string: self.url) else {
            AppLogger.shared.log("Invalid URL", .error)
            throw MusapError.internalError
        }
        
        AppLogger.shared.log("We are ending to URL: \(url.absoluteString)", .info)
        
        guard let msgType = msg.type,
              let payload = msg.payload
        else {
            AppLogger.shared.log("msg.type or pyload was nil", .error)
            throw MusapError.internalError
        }
        
        if shouldEncrypt && msgType != MusapLink.ENROLL_MSG_TYPE {
            guard let payloadHolder = self.getPayload(payloadBase64: payload, shouldEncrypt: shouldEncrypt)
            else
            {
                AppLogger.shared.log("Unable to send encrypted request", .error)
                throw MusapError.internalError
            }
            
            msg.payload = payloadHolder.getPayload()
            
            guard msg.payload != nil else {
                AppLogger.shared.log("Message payload was nil", .error)
                throw MusapError.internalError
            }
            msg.iv = payloadHolder.getIv()
            
            AppLogger.shared.log("Send request IV is: \(msg.iv ?? "(empty)")")
            
            do {
                msg.mac = try MusapLink.mac.generate(message: msg.payload ?? "", iv: msg.iv ?? "", transId: msg.getIdentifier(), type: msgType)

            } catch {
                print("Failed to generate mac")
                AppLogger.shared.log("Failed to generate message authentication code", .error)
                throw MusapError.internalError
            }
        }
        
        guard let jsonData = try? JSONEncoder().encode(msg) else {
            AppLogger.shared.log("Failed to encode message to JSON", .error)
            throw MusapError.internalError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        AppLogger.shared.log("Sending request...", .info)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let dataString = String(data: data, encoding: .utf8) {
            AppLogger.shared.log("Response as string: \(dataString)")
        } else {
            AppLogger.shared.log("Failed to convert Data() to String", .error)
        }
        
        guard !data.isEmpty else {
            AppLogger.shared.log("Data was empty", .error)
            throw MusapError.internalError
        }
        
        AppLogger.shared.log("trying to decode json from data", .info)
        let responseMsg = try JSONDecoder().decode(MusapMessage.self, from: data)
        
        AppLogger.shared.log("Parsing payload...")
        responseMsg.payload = self.parsePayload(respMsg: responseMsg, isEncrypted: shouldEncrypt)
        
        return responseMsg
    }

    
    public func sendRequest(_ msg: MusapMessage, shouldEncrypt: Bool, completion: @escaping (MusapMessage?, Error?) -> Void) {
        AppLogger.shared.log("Trying to send request. Should we encrypt?: \(shouldEncrypt)", .info)
        
        guard let msgType = msg.type,
              let payload = msg.payload
        else {
            AppLogger.shared.log("No message type or payload defined", .error)
            completion(nil, MusapError.internalError)
            return
        }
        
        AppLogger.shared.log("Payload is: \(payload)")
        
        if shouldEncrypt && msgType != MusapLink.ENROLL_MSG_TYPE {
            AppLogger.shared.log("Encrypting message...", .info)
            
            guard let holder = self.getPayload(payloadBase64: payload, shouldEncrypt: shouldEncrypt)
            else 
            {
                AppLogger.shared.log("Could not get PayloadHolder or IV", .error)
                completion(nil, MusapError.internalError)
                return
            }
            
            msg.payload = holder.getPayload()
            
            guard msg.payload != nil else {
                AppLogger.shared.log("No payload, can't send request", .error)
                completion(nil, MusapError.internalError)
                return
            }
            
            msg.iv = holder.getIv()
        
            do {
                msg.mac = try MusapLink.mac.generate(message: msg.payload ?? "", iv: msg.iv ?? "", transId: msg.getIdentifier(), type: msgType)
                AppLogger.shared.log("MAC string: \(msg.mac ?? "(empty)")")
            } catch {
                AppLogger.shared.log("Error while generating MAC: \(error)", .error)
            }
        }
        
        guard let jsonData = try? JSONEncoder().encode(msg) else {
            AppLogger.shared.log("Could not decode MusapMessage to JSON", .error)
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message"]))
            return
        }
        
        AppLogger.shared.log("JSON string: \(jsonData.base64EncodedString())")
        
        guard let url = URL(string: self.url) else {
            AppLogger.shared.log("Failed to send request, no URL", .error)
            completion(nil, MusapError.internalError)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLogger.shared.log("Got HTTP error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data, !data.isEmpty else {
                AppLogger.shared.log("Got no data after sending request", .error)
                completion(nil, nil)
                return
            }
        
            AppLogger.shared.log("Send request as B64 string: \(data.base64EncodedString())", .info)
            
            guard let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                AppLogger.shared.log("Failed to decode MusapMessage to JSON")
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                return
            }
            
            responseMsg.payload = self.parsePayload(respMsg: responseMsg, isEncrypted: shouldEncrypt)
            AppLogger.shared.log("Completed sendRequest, payload: \(responseMsg.payload ?? "(empty)")")
            completion(responseMsg, nil)
        }

        task.resume()
    }
    
    
    private func pollForSignature(transId: String, completion: @escaping (Result<ExternalSignatureResponsePayload, Error>) -> Void) {
        AppLogger.shared.log("Polling for signature...")
        
        var isPollingDone = false
        
        for i in 0..<MusapLink.POLL_AMOUNT {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2 * i)) {
                guard !isPollingDone else { return }
                
                self.performPollIteration(transId: transId) { result in
                
                    switch result {
                    case .failure:
                        AppLogger.shared.log("Polling failed.", .error)
                        isPollingDone = true
                        DispatchQueue.main.async {
                            completion(.failure(MusapError.internalError))
                        }
                    case .success(let response):
                        AppLogger.shared.log("Polled successfully for signature: \(response.signature ?? "(empty)")")
                        
                        isPollingDone = true
                        DispatchQueue.main.async {
                            completion(.success(response))
                        }
                    case .keepPolling:
                        AppLogger.shared.log("Still polling...")
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
        AppLogger.shared.log("Performing poll iteration...")
        
        let payload = ExternalSignaturePayload()
        payload.transid = transId
        
        guard let payloadBase64 = payload.getBase64Encoded() else {
            AppLogger.shared.log("Payload as B64 was nil. Poll iteration failed.", .error)
            completion(.failure)
            return
        }
        
        let musapMsg = MusapMessage()
        musapMsg.payload = payloadBase64
        musapMsg.type    = MusapLink.SIGN_MSG_TYPE
        musapMsg.musapid = self.getMusapId()
        
        self.sendRequest(musapMsg, shouldEncrypt: true) { respMsg, error in
            if let error = error {
                AppLogger.shared.log("Error in poll iteration: \(error.localizedDescription)")
                completion(.failure)
                return
            }
            
            guard let respMsg = respMsg else {
                AppLogger.shared.log("respMsg was nil", .error)
                completion(.keepPolling)
                return
            }
                    
            AppLogger.shared.log("Payload: \(respMsg.payload ?? "(empty)")")
            
            guard let msgPayload = respMsg.payload,
                  let payloadData = msgPayload.data(using: .utf8) else {
                completion(.failure)
                return
            }
            
            if let resp = try? JSONDecoder().decode(ExternalSignatureResponsePayload.self, from: payloadData) {
                if resp.status == "pending" {
                    AppLogger.shared.log("Status is pending...")
                    completion(.keepPolling)
                } else if resp.status == "failed" {
                    AppLogger.shared.log("Status was marked as failed", .error)
                    completion(.failure)
                } else {
                    AppLogger.shared.log("Returning success: \(resp.isSuccess())")
                    completion(.success(resp))
                }
            } else {
                completion(.failure)
            }
            
        }
        
    }
    
    private func getPayload(payloadBase64: String, shouldEncrypt: Bool) -> PayloadHolder? {
        AppLogger.shared.log("Trying to get payload...")

        if shouldEncrypt {
            guard let payloadHolder = MusapLink.encryption.encrypt(message: payloadBase64) else {
                AppLogger.shared.log("Could not encrypt payloadBase64.", .error)
                return nil
            }
            
            AppLogger.shared.log("Returning encrypted payload")
            return payloadHolder
        }

        AppLogger.shared.log("Returning unencrypted payload", .info)
        return PayloadHolder(payload: payloadBase64, iv: nil)
    }
    
    public func parsePayload(respMsg: MusapMessage, isEncrypted: Bool) -> String? {
        AppLogger.shared.log("Starting to parsePayload...", .info)
        
        if isEncrypted {
            
            AppLogger.shared.log("Message is encrypted, \(respMsg)")
            
            guard let payload = respMsg.payload else {
                AppLogger.shared.log("No payload, couldnt parse", .error)
                return nil
            }
            
            guard let decodedPayload = Data(base64Encoded: payload) else {
                AppLogger.shared.log("Cant turn payload to Data()", .error)
                return nil
            }
            
            guard let iv = respMsg.iv else {
                AppLogger.shared.log("No IV was found in MusapMessage", .error)
                return nil
            }
            
            let decrypted = MusapLink.encryption.decrypt(message: decodedPayload, iv: iv)
            AppLogger.shared.log("Decrypted payload: \(String(describing: decrypted))", .info)
            return decrypted
        }
        
        guard let message = respMsg.payload,
              let data = Data(base64Encoded: message)
        else {
            return nil
        }
        
        let decodedString = String(data: data, encoding: .utf8)
        AppLogger.shared.log("Decoded string: \(decodedString ?? "(empty)")", .info)
        
        return decodedString
    }
    
    private func isMacValid(msg: MusapMessage) -> Bool {
        AppLogger.shared.log("Validating MAC...")
        
        guard let payload = msg.payload else {
            AppLogger.shared.log("Payload is missing, can't validate MAC", .error)
            return false
        }
        
        guard let iv = msg.iv else {
            AppLogger.shared.log("Missing IV, can't validate MAC", .error)
            return false
        }
        
        guard let transid = msg.transid else {
            AppLogger.shared.log("Missing TransID, can't validate MAC", .error)
            return false
        }
        
        guard let type = msg.type else {
            AppLogger.shared.log("Missing Type, can't validate MAC", .error)
            return false
        }
        
        guard let mac = msg.mac else {
            AppLogger.shared.log("Missing MAC, can't validate MAC", .error)
            return false
        }
        
        do {
            return try MusapLink.mac.validate(message: payload, iv: iv, transId: transid, type: type, mac: mac)
        } catch {
            AppLogger.shared.log("MAC was invalid", .error)
            return false
        }
        
    }
    
    public func updateApnsToken(apnsToken: String) -> Bool {
        //TODO: Implement this
        return false
    }
    
}
