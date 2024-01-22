import Foundation

public class PollTask {

    typealias CompletionHandler = (Result<PollResponsePayload, MusapError>) -> Void

    private let link: MusapLink

    init(link: MusapLink) {
        self.link = link
    }

    func pollAsync(completion: @escaping CompletionHandler) async throws -> PollResponsePayload {
        do {
            guard let payload = try await self.link.poll() else {
                throw MusapError.internalError
            }
            
            completion(.success(payload))
            return payload
        } catch {
            completion(.failure(error as? MusapError ?? MusapError.internalError))
            throw error
        }
    }
}
