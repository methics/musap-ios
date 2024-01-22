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
    
    private static let POLL_AMOUNT = 20
    
    private let url:     String
    private var musapId: String?
    private var aesKey:  String?
    private var macKey:  String?
    
    public init(url: String, musapId: String?) {
        self.url = url
        self.musapId = musapId
    }
    
    public func setMusapId(musapId: String) {
        self.musapId = musapId
    }
    
    public func setAesKey(aesKey: String) {
        self.aesKey = aesKey
    }
    
    public func setMacKey(macKey: String) {
        self.macKey = macKey
    }
    
    public func encrypt(msg: MusapMessage) {
        //TODO:
    }
    
    public func decrypt(msg: MusapMessage) {
        //TODO:
    }
    
    /**
    Enroll this MUSAP instance with MUSAP Link
     - returns: MusapLink
     - throws:  MusapError
     */
    public func enroll(apnsToken: String?) async throws -> MusapLink {
        let payload = EnrollDataPayload(apnsToken: apnsToken)
        
        guard let payload = payload.getBase64Encoded() else {
            print("MusapLink.enroll(): no payload")
            throw MusapError.internalError
        }
        
        let msg = MusapMessage()
        msg.payload = payload
        msg.type    = MusapLink.ENROLL_MSG_TYPE
        
        guard let url = URL(string: self.url) else {
            print("Could not create URL object")
            throw MusapError.internalError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(msg)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode to JSON")
            throw MusapError.internalError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Bad http response or statuscode: \(response)")
            throw MusapError.internalError
        }
        
        do {
            // Get the MusapMessage from json
            let decodedMessage = try JSONDecoder().decode(MusapMessage.self, from: data)
            
            // Make sure payload is there, and turn it into data from base64encoded str
            guard let payloadBase64 = decodedMessage.payload,
                  let payloadData = Data(base64Encoded: payloadBase64)
            else {
                print("Failed to turn payload to data")
                throw MusapError.internalError
            }
            
            // Turn the data to EnrollDataResponsePayload
            let enrollDataResponsePayload = try JSONDecoder().decode(EnrollDataResponsePayload.self, from: payloadData)
            
            // Make sure the musap ID is there since it is required
            guard let musapId = enrollDataResponsePayload.musapid else {
                print("enroll: Could not get Musap ID ")
                throw MusapError.internalError
            }
            
            // Return MusapLink
            self.musapId = musapId
            return self
        } catch {
            print("error in enroll with json: \(error)")
        }

        // if we got to here, there was some error
        throw MusapError.internalError
    }
    
    
    /**
      Couple this MUSAP with a MUSAP Link.
      This performs networking operations.
     - parameters:
       - returns: RelyingParty if pairing was a success
     */
    public func couple(couplingCode: String, musapid: String) async throws -> RelyingParty {
        let payload = LinkAccountPayload(couplingcode: couplingCode, musapid: musapid)
        
        let msg = MusapMessage()
        msg.type = MusapLink.COUPLE_MSG_TYPE
        
        if let payload = payload.getBase64Encoded() {
            msg.payload = payload
        } else {
            print("MusapLink.couple(): Failed to get base64")
            throw MusapError.internalError
        }
        
        guard let url = URL(string: self.url) else {
            print("MusapLink.couple(): Failed get URL")
            throw MusapError.internalError
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
                print("COUPLING request body: \(jsonString)")
            }
            
        } catch {
            print("error encoding json: \(error)")

            throw MusapError.internalError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("MusapLink.couple(): HTTP ERROR?")
            throw MusapError.internalError
        }
        
        do {
            // Form a MusapMessage from server response
            let musapMessage = try JSONDecoder().decode(MusapMessage.self, from: data)
            
            // Make sure payload is there, and turn it into data from base64encoded str
            guard let payloadBase64 = musapMessage.payload,
                  let payloadData = Data(base64Encoded: payloadBase64) 
            else {
                print("Failed to turn payload to data")
                throw MusapError.internalError
            }
            
            print("JSON: \(String(describing: String(data: payloadData, encoding: .utf8)))")
            
            // Turn the data to LinkAccountResponsePayload
            let linkAccountResponsePayload = try JSONDecoder().decode(LinkAccountResponsePayload.self, from: payloadData)
            //TODO: This should probably error better

            // Get the Link ID and RP name
            let linkId = linkAccountResponsePayload.linkid
            let rpName = linkAccountResponsePayload.name
            
            let rp = RelyingParty(name: rpName, linkId: linkId)
            return rp
            
        } catch {
            print("Error while coupling: \(error)")
        }
        
        throw MusapError.internalError
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
    
    public func sendSignatureCallback(signature: MusapSignature, transId: String) throws {
        let payload = SignatureCallbackPayload(linkid: nil, signature: signature)
        
        let msg = MusapMessage()
        msg.type = MusapLink.SIG_CALLBACK_MSG_TYPE
        msg.payload = payload.getBase64Encoded()
        msg.musapid = self.musapId
        msg.transid = transId
        
        print("signatureCallback: MusapMEssage created. Payload: \(String(describing: payload.getBase64Encoded()))")
        
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
            
            print("Response payload: \(String(describing: responseMsg.payload))")
            
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

        self.sendRequest(msg) { respMsg, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                print("MusapLink.sign() error: \(error)")
                return
            }

            guard let resp = respMsg else {
                print("No Resp message")
                return
            }
            
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
    
    public func sendRequest(_ msg: MusapMessage, completion: @escaping (MusapMessage?, Error?) -> Void) {
        print("start of sendRequest")
        
        print("")
        
        debugPrint(msg)
        
        debugPrint("msg payload: \(String(describing: msg.payload))")
        
        print("")
        //TODO: Problem lies here?
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

            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("sendRequest jsonString from retrieved http data: \(jsonString)")
                    if jsonString == "null" {
                        print("jsonString was null, trying to send completion(nil, nil)")
                        completion(nil, nil)
                        return
                    }
                }
            }
            
            guard let data = data else {
                print("sendRequest: No data")
                completion(nil, error)
                return
            }

            guard let responseMsg = try? JSONDecoder().decode(MusapMessage.self, from: data)
            else {
                print("Failed to parse json to MusapMEssage")
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                return
            }
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
                let payload = ExternalSignaturePayload()
                payload.transid = transId

                guard let payloadBase64 = payload.getBase64Encoded() else {
                    completion(.failure(MusapError.internalError))
                    return
                }

                let msg = MusapMessage()
                msg.payload = payloadBase64
                msg.type    = MusapLink.SIGN_MSG_TYPE
                msg.musapid = self.getMusapId()

                self.sendRequest(msg) { respMsg, error in
                    /*
                    if let error = error {
                        print("MusapLink.pollForSignature: We had an error in the link response")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }

                     */
                    guard let respMsg = respMsg,
                          let msgPayload = respMsg.payload,
                          let payloadData = Data(base64Encoded: msgPayload) else {
                        DispatchQueue.main.async {
                            completion(.failure(MusapError.internalError))
                        }
                        return
                    }

                    if let resp = try? JSONDecoder().decode(ExternalSignatureResponsePayload.self, from: payloadData) {
                        DispatchQueue.main.async {
                            if resp.status == "pending" {
                                print("Status is pending")
                                return
                            } else if resp.status == "failed" {
                                print("Status was marked as failed")
                                isPollingDone = true
                                completion(.failure(MusapError.internalError))
                                return
                            }

                            print("Returning success")
                            isPollingDone = true
                            completion(.success(resp))
                            return
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(MusapError.internalError))
                        }
                    }
                }
            }
        }
    }
    
    public func getMusapId() -> String? {
        return self.musapId
    }
    
}
