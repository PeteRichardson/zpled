//
//  ZD620.swift
//  zpled
//
//  Created by Peter Richardson on 8/19/25.
//
import Network

func sendZPL(to host: String, port: UInt16 = 9100, zpl: String) async throws {
    let conn = NWConnection(
        host: NWEndpoint.Host(host),
        port: NWEndpoint.Port(rawValue: port)!,
        using: .tcp
    )

    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                conn.send(
                    content: zpl.data(using: .utf8),
                    completion: .contentProcessed { sendError in
                        if let sendError = sendError {
                            conn.cancel()
                            cont.resume(throwing: sendError)
                        } else {
                            conn.cancel()
                            cont.resume(returning: ())
                        }
                    }
                )
            case .failed(let error):
                conn.cancel()
                cont.resume(throwing: error)
            default:
                break
            }
        }
        conn.start(queue: .global())
    }
}
