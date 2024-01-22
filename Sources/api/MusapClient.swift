//
//  MusapClient.swift
//  MUSAP-demo-app-ios
//
//  Created by Teemu Mänttäri on 3.11.2023.
//

import Foundation

public class MusapClient {
    
    /**
     Generate a keypair and store the key metadata to MUSAP.
     - Parameters:
       - sscd: An instance conforming to `MusapSscdProtocol`, providing security services for key generation.
       - req: A `KeyGenReq` instance specifying key generation parameters like key alias, role, policy, attributes, and algorithm.
       - completion: A completion handler called with a `Result` type containing `MusapKey` on success or `MusapError` on failure.

     - Note: The method handles the asynchronous task internally and uses the `GenerateKeyTask` for the key generation process.
     */
    public static func generateKey(sscd: any MusapSscdProtocol, req: KeyGenReq, completion: @escaping (Result<MusapKey, MusapError>) -> Void) async {
        do {
            let generateKeyTask = GenerateKeyTask()
            let key = try await generateKeyTask.generateKeyAsync(sscd: sscd, req: req, completion: completion)
            completion(.success(key))
        } catch {
            completion(.failure(MusapError.internalError))
        }
    }

    /**
     Binds a keypair and stores its metadata in MUSAP.

     - Parameters:
       - sscd: The SSCD used for binding the key.
       - req: A `KeyBindReq` instance, specifying the key binding requirements.
       - completion: A completion handler returning a `Result` with either a `MusapKey` on success or a `MusapError` on failure.

     - Note: Asynchronous execution, leveraging `BindKeyTask` for the key binding operation.
     */
    public static func bindKey(sscd: any MusapSscdProtocol, req: KeyBindReq, completion: @escaping (Result<MusapKey, MusapError>) -> Void) async {
        let bindKeyTask = BindKeyTask()
        do {
            let musapKey = try await bindKeyTask.bindKey(req: req, sscd: sscd)
            completion(.success(musapKey))
        } catch {
            completion(.failure(MusapError.bindUnsupported))
        }
    }
    
    /**
     Signs data using a specified SSCD.

     - Parameters:
       - req: A `SignatureReq` detailing the signature request.
       - completion: A completion handler that returns a `Result` with either `MusapSignature` on success or `MusapError` on failure.

     - Note: The signing process is asynchronous, utilizing `SignTask` for the operation.
     */
    public static func sign(req: SignatureReq, completion: @escaping (Result<MusapSignature, MusapError>) -> Void) async {
        do {
            let signTask = SignTask()
            let signature = try await signTask.sign(req: req)
            completion(.success(signature))
        } catch let musapError as MusapError {
            completion(.failure(musapError))
        } catch {
            completion(.failure(MusapError.internalError))
        }
    }
    
    /**
     Lists SSCDs enabled in the MUSAP library. Add an SSCD using `enableSscd` before listing.

     - Returns: An array of enabled SSCDs conforming to `MusapSscdProtocol`, or nil if no SSCDs are enabled.
     */
    public static func listEnabledSscds() -> [any MusapSscdProtocol]? {
        let keyDiscovery = KeyDiscoveryAPI(storage: MetadataStorage())
        let enabledSscds = keyDiscovery.listEnabledSscds()
        print("enabledSscds in MusapClient: \(enabledSscds.count)")
        return enabledSscds
    }
    
    /**
     Lists enabled SSCDs based on specified search criteria.

     - Parameters:
       - req: A `SscdSearchReq` to filter the list of SSCDs.
     - Returns: An array of SSCDs matching the search criteria.
     */
    public static func listEnabledSscds(req: SscdSearchReq) -> [any MusapSscdProtocol] {
        let keyDiscovery = KeyDiscoveryAPI(storage: MetadataStorage())
        
        //TODO: Will this work? What is the issue?
        return keyDiscovery.listMatchingSscds(req: req)
    }
    
    /**
     Lists active SSCDs with user-generated or bound keys.

     - Returns: An array of active SSCDs that can generate or bind keys.
     */

    public static func listActiveSscds() -> [MusapSscd] {
        return KeyDiscoveryAPI(storage: MetadataStorage()).listActiveSscds()
    }
    
    /**
     Lists active SSCDs based on specified search criteria.

     - Parameters:
       - req: A `SscdSearchReq` to filter the list of active SSCDs.
     - Returns: An array of active `MusapSscd` objects matching the search criteria.
     */
    public static func listActiveSscds(req: SscdSearchReq) -> [MusapSscd] {
        let keyDiscovery = KeyDiscoveryAPI(storage: MetadataStorage())
        return keyDiscovery.listActiveSscds()
    }
    
    /**
     Lists all available Musap Keys.

     - Returns: An array of `MusapKey` instances found in storage.
     */
    public static func listKeys() -> [MusapKey] {
        let keys = MetadataStorage().listKeys()
        print("Found: \(keys.count) keys from storage")
        return keys
    }
    
    /**
     Lists keys matching given search parameters.

     - Parameters:
       - req: A `KeySearchReq` to filter the list of keys.
     - Returns: An array of `MusapKey` instances matching the search criteria.
     */
    public static func listKeys(req: KeySearchReq) -> [MusapKey] {
        let keys = MetadataStorage().listKeys(req: req)
        print("Found: \(keys.count) keys from storage")
        return keys
    }
    /**
     Enables an SSCD for use with MUSAP. Must be called for each SSCD the application intends to support.

     - Parameters:
       - sscd: The SSCD to be enabled.
     */
    public static func enableSscd(sscd: any MusapSscdProtocol) {
        let keyDiscovery = KeyDiscoveryAPI(storage: MetadataStorage())
        keyDiscovery.enableSscd(sscd)
    }
    
    /**
     Retrieves a `MusapKey` based on a given KeyURI string.

     - Parameters:
       - keyUri: The KeyURI as a string.
     - Returns: An optional `MusapKey` matching the provided KeyURI.
     */
    public static func getKeyByUri(keyUri: String) -> MusapKey? {
        let keyList = MetadataStorage().listKeys()
        let keyUri = KeyURI(keyUri: keyUri)
        
        for key in keyList {
            if let loopKeyUri = key.getKeyUri() {
                if loopKeyUri.keyUriMatches(keyUri: keyUri) {
                    return key
                }
            }
        }
        
        return nil
    }
    
    /**
     Retrieves a `MusapKey` based on a provided KeyURI object.

     - Parameters:
       - keyUriObject: A `KeyURI` object.
     - Returns: An optional `MusapKey` matching the KeyURI object.
     */
    public static func getKeyByUri(keyUriObject: KeyURI) -> MusapKey? {
        let keyList = MetadataStorage().listKeys()
        
        for key in keyList {
            if let loopKeyUri = key.getKeyUri() {
                if loopKeyUri.keyUriMatches(keyUri: keyUriObject) {
                    return key
                }
            }
        }
        
        return nil
    }
    
    /**
     Imports MUSAP key data and SSCD details from JSON.

     - Parameters:
       - data: JSON string containing MUSAP data.
     - Throws: `MusapError` if the data cannot be parsed or is invalid.
     */
    public static func importData(data: String) throws {
        let storage = MetadataStorage()
        guard let importData = MusapImportData.fromJson(jsonString: data) else {
            throw MusapError.internalError
        }
        
        try storage.addImportData(data: importData)
        
    }
    
    /**
     Exports MUSAP key data and SSCD details as a JSON string.

     - Returns: A JSON string representing MUSAP data, or nil if the data cannot be exported.
     */
    public static func exportData() -> String? {
        let storage = MetadataStorage()
        
        guard let exportData = storage.getImportData().toJson() else {
            print("Could not export data")
            return nil
        }
        
        return exportData
    }
    
    /**
     Remove a key from MUSAP.
     - Parameters:
        - key: MusapKey to remove
     - Returns: `Bool`
     */
    public static func removeKey(musapKey: MusapKey) -> Bool {
        return KeyDiscoveryAPI(storage: MetadataStorage()).removeKey(key: musapKey)
    }
    
    /**
     Remove an active SSCD from MUSAP
     - Parameters:
        - musapSscd: SSCD to remove
     */
    public static func removeSscd(musapSscd: String) {
        //TODO: code this
    }
    
    public static func listRelyingParties() -> [RelyingParty]? {
        return MusapStorage().listRelyingParties()
    }
    
    public static func removeRelyingParty(relyingParty: RelyingParty) -> Bool {
        return MusapStorage().removeRelyingParty(rp: relyingParty)
    }
    
    /**
        Enable a MUSAP Link connection
        Enabling allows the MUSAP Link to securely request signatures from this MUSAP.
     - Note: Only one connection can be active at a time
     - Parameters:
       - url: URL of the MUSAP Link service
       - apnsToken: apple push notification service token
     */
    public static func enableLink(url: String, apnsToken: String?) async -> MusapLink? {
        let link = MusapLink(url: url, musapId: nil)
        let enrollTask = EnrollDataTask(link: link, apnsToken: apnsToken)
        do {
            let link = try await enrollTask.enrollData()
            return link
        } catch {
            print("error enabling link: \(error)")
            return nil
        }
    }
    
    public static func disableLink() -> Void {
        MusapStorage().removeLink()
    }
    
    public static func sendSignatureCallback() {
        //TODO: DO THIS?
    }
    
    public static func sendKeygenCallback() {
        //TODO: Do this?
    }
    
    public static func updateApnsToken() {
        //TODO: Do this
    }
    
    public static func pollLink(completion: @escaping (Result<PollResponsePayload, MusapError>) -> Void) async {
        guard let link = self.getMusapLink() else {
            completion(.failure(MusapError.internalError))
            return
        }
        
        do {
            let pollResponsePayload = try await PollTask(link: link).pollAsync() { result in
                
                switch result {
                case .success(let payload):
                    completion(.success(payload))
                    return
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                
            }
        } catch {
            completion(.failure(MusapError.internalError))
        }
        
    }
    
    public static func isLinkEnabled() -> Bool {
        return self.getMusapId() != nil
    }
    
    public static func updateKey(req: UpdateKeyReq) -> Bool {
        let storage = MetadataStorage()
        return storage.updateKeyMetaData(req: req)
    }
    
    public static func getMusapId() -> String? {
        return MusapStorage().getMusapId()
    }
    
    public static func getMusapLink() -> MusapLink? {
        return MusapStorage().getMusaplink()
    }
    
    /**
     Request coupling with an RP.
     This requires a coupling code which can be retrieved by the web service via the MUSAP Link API.
     - parameters:
        - couplingCode: Coupling code entered by the user.
        - completion:   CompletionHandler
     */
    public static func coupleWithRelyingParty(couplingCode: String, completion: @escaping (Result<RelyingParty, MusapError>) -> Void) async {
        guard let musapId = self.getMusapId() else {
            print("Error in coupling with relying party: No Musap ID")
            return
        }
        
        guard let link = self.getMusapLink() else {
            print("No musap link")
            return
        }
        
        do {
            let rp = try await CoupleTask().couple(link: link, couplingCode: couplingCode, appId: musapId)
            completion(.success(rp))
        } catch {
            print("Error in coupleWithRelyingParty: \(error)")
            completion(.failure(MusapError.internalError))
        }
        
    }
    
    
}

