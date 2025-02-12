//
//  ListLivestreams.swift
//  Odysee
//
//  Created by Keith Toh on 22/04/2022.
//

import Foundation

struct OdyseeLivestream {
    static let apiEndpoint = URL(string: "https://api.odysee.live/livestream/all")!

    static func listLivestreams(completion: @escaping (_ result: Result<[String: LivestreamInfo], Error>) -> Void) {
        do {
            let data = try Data(contentsOf: apiEndpoint)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try decoder.decode(OLResult.self, from: data)
            if result.success && result.error == nil, let data = result.data {
                let livestreamInfos = Dictionary(
                    uniqueKeysWithValues: data
                        .filter { $0.activeClaim.claimId != "Confirming" }
                        .map {
                            (
                                $0.activeClaim.claimId,
                                LivestreamInfo(
                                    startTime: $0.startTime,
                                    viewerCount: $0.viewerCount,
                                    channelClaimId: $0.channelClaimId
                                )
                            )
                        }
                )
                completion(.success(livestreamInfos))
                return
            } else if result.data == nil,
                      let error = result.error,
                      let trace = result.trace
            {
                completion(.failure(OdyseeLivestreamError.runtimeError("\(error)\n---Trace---\n\(trace)")))
                return
            }
        } catch {
            completion(.failure(error))
            return
        }

        completion(.failure(OdyseeLivestreamError.noBranchTaken))
    }

    struct OLResult: Decodable {
        var success: Bool
        var error: String?
        var data: [OLLivestream]?
        var trace: [String]?

        enum CodingKeys: String, CodingKey {
            case success
            case error
            case data
            case trace = "_trace"
        }
    }

    struct OLLivestream: Decodable {
        var startTime: Date
        var viewerCount: Int
        var channelClaimId: String
        var activeClaim: OLClaim

        enum CodingKeys: String, CodingKey {
            case startTime = "Start"
            case viewerCount = "ViewerCount"
            case channelClaimId = "ChannelClaimID"
            case activeClaim = "ActiveClaim"
        }
    }

    struct OLClaim: Decodable {
        var claimId: String

        enum CodingKeys: String, CodingKey {
            case claimId = "ClaimID"
        }
    }
}

struct LivestreamInfo: Hashable {
    var startTime: Date
    var viewerCount: Int
    var channelClaimId: String
}

struct LivestreamData: Hashable {
    var startTime: Date
    var viewerCount: Int
    var claim: Claim
}

enum OdyseeLivestreamError: LocalizedError {
    case noBranchTaken
    case runtimeError(String)

    var errorDescription: String? {
        switch self {
        case .noBranchTaken:
            return String.localized("No result logic branch taken")
        case let .runtimeError(message):
            return String(format: String.localized("Runtime error: %@"), message)
        }
    }
}
