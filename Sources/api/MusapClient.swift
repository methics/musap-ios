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
       - sscd: An instance conforming to `MusapSscd`, providing security services for key generation.
       - req: A `KeyGenReq` instance specifying key generation parameters like key alias, role, policy, attributes, and algorithm.
       - completion: A completion handler called with a `Result` type containing `MusapKey` on success or `MusapError` on failure.

     - Note: The method handles the asynchronous task internally and uses the `GenerateKeyTask` for the key generation process.
     */
    public static func generateKey(sscd: MusapSscd, req: KeyGenReq, completion: @escaping (Result<MusapKey, MusapError>) -> Void) async {
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
    public static func bindKey(sscd: MusapSscd, req: KeyBindReq, completion: @escaping (Result<MusapKey, MusapError>) -> Void) async {
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
     List SSCDs supported by this MUSAP library. To add an SSCD to this list, MusapClient.enableSscd() first.
     - Returns: An array of enabled MusapSscd
     */
    public static func listEnabledSscds() -> [MusapSscd]? {
        let enabledSscds = KeyDiscoveryAPI(storage: MetadataStorage()).listEnabledSscds()
        
        AppLogger.shared.log("Listing SSCD's, found \(enabledSscds.count)", .debug)
        var musapSscds = [MusapSscd]()
        for sscd in enabledSscds {
            musapSscds.append(MusapSscd(impl: sscd))
        }
        return musapSscds
    }
    
    /**
     List SSCDs supported by this MUSAP library. To add an SSCD to this list, MusapClient.enableSscd() first.
     - Parameters:
        - req: SscdSearchReq that filters the output
     - Returns: An array of MusapSscd or nil if no matches
     */
    public static func listEnabledSscds(req: SscdSearchReq) -> [MusapSscd]? {
        AppLogger.shared.log("Trying to list SSCD's that match search options")
        guard let enabledSscds = self.listEnabledSscds() else {
            return [MusapSscd]()
        }
        
        var result = [MusapSscd]()
        
        for sscd in enabledSscds {
            guard let s = sscd.getSscdInfo() else {
                continue
            }
            if req.matches(sscd: s) {
                result.append(sscd)
            }
        }
        
        AppLogger.shared.log("Found \(result.count) SSCDs")
        
        return result
    }
    
    /**
     Lists enabled SSCDs based on specified search criteria.

     - Parameters:
       - req: A `SscdSearchReq` to filter the list of SSCDs.
     - Returns: An array of SSCDs matching the search criteria.
     */
    public static func listEnabledSscds(req: SscdSearchReq) -> [any MusapSscdProtocol] {
        let keyDiscovery = KeyDiscoveryAPI(storage: MetadataStorage())
        
        return keyDiscovery.listMatchingSscds(req: req)
    }
    
    /**
     Lists active SSCDs with user-generated or bound keys.
     
     - Returns: An array of active SSCDs that can generate or bind keys.
     */
    public static func listActiveSscds() -> [MusapSscd] {
        AppLogger.shared.log("Trying to list active SSCDs", .debug)
        guard let enabledSscds: [MusapSscd] = listEnabledSscds() else {
            AppLogger.shared.log("No enabled SSCD's found", .debug)
            return []
        }
        var activeSscds: [SscdInfo]  = MetadataStorage().listActiveSscds()
        var result = [MusapSscd]()
        
        AppLogger.shared.log("Got \(activeSscds.count) active SSCD's", .debug)
        
        for sscd in enabledSscds {
            guard let sscdId = sscd.getSscdId() else {
                AppLogger.shared.log("No SSCD ID for enabled SSCD, continue")
                continue
            }
            
            if activeSscds.contains(where: { $0.getSscdId() == sscdId}) {
                result.append(sscd)
            }
        }
        
        AppLogger.shared.log("Found \(result.count) active SSCDs")
        
        return result
    }
    
    /**
     Lists active SSCDs based on specified search criteria.

     - Parameters:
       - req: A `SscdSearchReq` to filter the list of active SSCDs.
     - Returns: An array of active `MusapSscd` objects matching the search criteria.
     */
    public static func listActiveSscds(req: SscdSearchReq) -> [MusapSscd] {
        let activeSscds = self.listActiveSscds()
        
        guard activeSscds.count > 0 else {
            AppLogger.shared.log("Got 0 active SSCD's")
            return [MusapSscd]()
        }
        
        var result = [MusapSscd]()
        
        for sscd in activeSscds {
            guard let sscdInfo = sscd.getSscdInfo() else {
                continue
            }
            if req.matches(sscd: sscdInfo) {
                result.append(sscd)
            }
        }
        
        AppLogger.shared.log("Found \(result.count) active SSCD's")
        
        return result
    }
    
    /**
     Lists all available Musap Keys.

     - Returns: An array of `MusapKey` instances found in storage.
     */
    public static func listKeys() -> [MusapKey] {
        let keys = MetadataStorage().listKeys()
        AppLogger.shared.log("Found \(keys.count) keys from storage")
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
        AppLogger.shared.log("Found \(keys.count) keys from storage matching the KeySearchReq")
        return keys
    }
    /**
     Enables an SSCD for use with MUSAP. Must be called for each SSCD the application intends to support.

     - Parameters:
       - sscd: The SSCD to be enabled.
     */
    public static func enableSscd(sscd: any MusapSscdProtocol, sscdId: String) {
        sscd.getSettings().setSetting(key: "id", value: sscdId)
        
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
        AppLogger.shared.log("Trying to get key by URI: \(keyUri)")
        let keyList = MetadataStorage().listKeys()
        let keyUri = KeyURI(keyUri: keyUri)
        
        for key in keyList {
            if let loopKeyUri = key.getKeyUri() {
                if loopKeyUri.keyUriMatches(keyUri: keyUri) {
                    AppLogger.shared.log("Found key with URI: \(keyUri)")
                    return key
                }
            }
        }
        
        AppLogger.shared.log("No key found matching URI: \(keyUri)")
        
        return nil
    }
    
    /**
     Retrieves a `MusapKey` based on a provided KeyURI object.

     - Parameters:
       - keyUriObject: A `KeyURI` object.
     - Returns: An optional `MusapKey` matching the KeyURI object.
     */
    public static func getKeyByUri(keyUriObject: KeyURI) -> MusapKey? {
        AppLogger.shared.log("Trying to get key by URI: \(keyUriObject.getUri())")
        let keyList = MetadataStorage().listKeys()
        
        for key in keyList {
            if let loopKeyUri = key.getKeyUri() {
                if loopKeyUri.keyUriMatches(keyUri: keyUriObject) {
                    AppLogger.shared.log("Found key with alias: \(key.getKeyAlias() ?? "(no alias)")")
                    return key
                }
            }
        }
        
        AppLogger.shared.log("No key found with uri \(keyUriObject.getUri())")
        return nil
    }
    
    /**
    Get a key by KeyID
    - Parameters:
       - keyId: Key ID as string
     - Returns: MusapKey or nil
     
     */
    public static func getKeyByKeyId(keyId: String) -> MusapKey? {
        AppLogger.shared.log("Trying to get key by id: \(keyId)")
        
        let keyList = MetadataStorage().listKeys()
        
        for key in keyList {
            if let loopKeyId = key.getKeyId() {
                if loopKeyId == keyId {
                    AppLogger.shared.log("Found key with alias: \(key.getKeyAlias() ?? "(no alias)")")
                    return key
                }
            }
        }

        AppLogger.shared.log("No key found with ID \(keyId)")
        return nil
    }
    
    /**
     Imports MUSAP key data and SSCD details from JSON.

     - Parameters:
       - data: JSON string containing MUSAP data.
     - Throws: `MusapError` if the data cannot be parsed or is invalid.
     */
    public static func importData(data: String) throws {
        AppLogger.shared.log("Trying to import MUSAP key data")
        
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

        AppLogger.shared.log("Trying to export MUSAP data")
        guard let exportData = storage.getImportData().toJson() else {
            AppLogger.shared.log("Export failed. Could not export data.", .error)
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
    public static func removeSscd(musapSscd: SscdInfo) -> Bool {
        return MetadataStorage().removeSscd(sscd: musapSscd)
    }
    
    /**
     List enrolled relying parties
      - Returns: List of relying parties or nil
     */
    public static func listRelyingParties() -> [RelyingParty]? {
        return MusapStorage().listRelyingParties()
    }
    
    /**
     Remove a previously linked Relying Party from this MUSAP app.
     - Parameters:
        - relyingParty: Relying party to remove
     */
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
            AppLogger.shared.log("Unable to enable MUSAP Link: \(error)")
            return nil
        }
    }
    
    /**
     Disable the MUSAP Link connection
     */
    public static func disableLink() -> Void {
        MusapStorage().removeLink()
    }
    
    /**
    Send SignatureCallback to MUSAP Link
     - Parameters:
        - signature: MusapSignature returned from MusapLink.sign()
        - txnId:     Transaction ID
     */
    public static func sendSignatureCallback(signature: MusapSignature, txnId: String) {
        AppLogger.shared.log("Trying to send signature callback")
        guard let link = self.getMusapLink() else {
            AppLogger.shared.log("Could not find MusapLink", .error)
            return
        }
        
        guard let musapId = self.getMusapId() else {
            AppLogger.shared.log("Could not get MUSAP ID", .error)
            return
        }
        
        link.setMusapId(musapId: musapId)
        
        do {
            AppLogger.shared.log("Sending callback with MUSAP ID: \(musapId)")
            try SignatureCallbackTask().runTask(link: link, signature: signature, txnId: txnId)
        } catch {
            AppLogger.shared.log("Failed to send signature callback: \(error)")
        }
        
    }
    
    /**
     Send a GenerateKeyCallback to MUSAP Link
        - Parameters:
           - key: MusapKey
           - txnId: Transaction ID
     */
    public static func sendKeygenCallback(key: MusapKey, txnId: String) {
        AppLogger.shared.log("Starting sendKeygenCallback", .debug)
        guard let link = self.getMusapLink(),
              let musapId = self.getMusapId()
        else {
            return
        }
        
        link.setMusapId(musapId: musapId)
        
        do {
            AppLogger.shared.log("Trying to send KeygenCallback with MUSAP ID: \(musapId)")
            try KeygenCallbackTask().runTask(link: link, key: key, txnId: txnId)
        } catch {
            AppLogger.shared.log("Failed to send KeygenCallback: \(error)")
        }
        
    }
    
    /**
            Send an updated APNs token to the MUSAP Link. If MUSAP Link is not enabled, this does nothing.
     */
    public static func updateApnsToken(apnsToken: String) {
        // TODO: Complete
    }
    
    
    /**
      Poll MUSAP Link for an incoming signature request. This should be called periodically and/or
      when a notification wakes up the application.
      Calls the callback when when signature is received, or polling failed.
      - parameters:
        - completion: Callback to deliver the result
     */
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
    
    /**
    Check if MUSAP Link has been enabled.
    - returns: Bool
     */
    public static func isLinkEnabled() -> Bool {
        return self.getMusapId() != nil
    }
    
    /**
    Update previously saved key metadata
     - Parameters:
        - req: UpdateKeyReq
     */
    public static func updateKey(req: UpdateKeyReq) -> Bool {
        let storage = MetadataStorage()
        return storage.updateKeyMetaData(req: req)
    }
    
    /**
    Get saved MUSAP ID.
     - Returns: MUSAP ID as string or nil
     */
    public static func getMusapId() -> String? {
        return MusapStorage().getMusapId()
    }
    
    /**
    Get MUSAP Link
     - returns: MusapLink or nil
     */
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
            AppLogger.shared.log("Error coupling with relying party: No Musap ID")
            return
        }
        
        guard let link = self.getMusapLink() else {
            AppLogger.shared.log("No MUSAP Link found, coupling failed")
            return
        }
        
        do {
            let rp = try await CoupleTask().couple(link: link, couplingCode: couplingCode, appId: musapId)
            completion(.success(rp))
        } catch {
            AppLogger.shared.log("Error with coupling: \(error)")
            completion(.failure(MusapError.internalError))
        }
        
    }
    
    
}

