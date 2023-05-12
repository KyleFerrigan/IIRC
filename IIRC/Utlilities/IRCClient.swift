//
//  IRCClient.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//
import Foundation
import Network

class IRCClient: ObservableObject {
	var connection: NWConnection?
	let queue = DispatchQueue(label: "IRC Queue")
	var pingTimer: Timer?
	var hostStr: String = ""
	var hasReceivedMOTD = false
	var server: String?
	@Published var messages: [String] = []
	
	func connect(host: String, port: UInt16, nickname: String, channel: String) {
		self.hostStr = host
		let parameters = NWParameters.tcp
		let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(integerLiteral: 6667))
		
		connection = NWConnection(to: endpoint, using: parameters)
		connection?.stateUpdateHandler = { newState in
			switch newState {
				case .ready:
					print("Ready to send")
					self.setupReceive()
					self.joinChannel(nickname: nickname, channel: channel)
				case .failed(let error):
					print("Connection Failed: ", error)
				default:
					break
			}
		}
		connection?.start(queue: queue)
	}
	
	func joinChannel(nickname: String, channel: String) {
		sendMessage("NICK \(nickname)\r\n")
		sendMessage("USER \(nickname) 0 * :\(nickname)\r\n")
		sendMessage("JOIN #\(channel)\r\n")
		pingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
			self.sendMessage("PING :irc\r\n")
		}
	}
	
	func sendMessage(_ message: String) {
		let data = message.data(using: .utf8)!
		connection?.send(content: data, completion: .contentProcessed({ error in
			if let error = error {
				print("Send error: ", error)
			}
		}))
	}
	
	func sendChatMessage(_ message: String, to channel: String) {
		sendMessage("PRIVMSG #\(channel) :\(message)\r\n")
	}
	
	func processIRCMessage(_ message: String) -> [(nickname: String, message: String)] {
		let lines = message.components(separatedBy: "\r\n")
		
		var filteredMessages: [(nickname: String, message: String)] = []
		
		//TODO use this as a template for better filtering of messages
		//Move pong up here too
		//for line in lines {
		//
		//	var messageContent: String
		//	var nickname: String
		//
		//	if line.contains("PRIVMSG") == true { //User Messages
		//		// Extract the nickname
		//		nickname =
		//		messageContent =
		//	}
		//
		//	// Append the filtered message to the result
		//	filteredMessages.append((nickname, messageContent))
		//}
		
		for line in lines {
			let components = line.components(separatedBy: " ")
			
			// Ensure the line has at least 4 components
			guard components.count >= 4 else { continue }
			
			var messageContent: String
			var nickname: String
			
			if components[0].firstIndex(of: "!") == nil { //Server messages
				nickname = "SERVER"
				// Extract the message content
				let startIndex = components[0].count + components[1].count + components[2].count + components[3].count + 3
				let endIndex = line.count
				messageContent = String(line[line.index(line.startIndex, offsetBy: startIndex)..<line.index(line.startIndex, offsetBy: endIndex)])
			} else { //User messages
				// Extract the nickname
				nickname = String(components[0].dropFirst().dropLast(components[0].distance(from: components[0].firstIndex(of: "!") ?? components[0].startIndex, to: components[0].endIndex)))
				let startIndex = components[0].count + components[1].count + components[2].count
				let endIndex = line.count
				messageContent = String(line[line.index(line.startIndex, offsetBy: startIndex)..<line.index(line.startIndex, offsetBy: endIndex)])
			}
			
			
			
			
			// Append the filtered message to the result
			filteredMessages.append((nickname, messageContent))
		}
		
		return filteredMessages
	}
	
	func setupReceive() {
		connection?.receive(minimumIncompleteLength: 1, maximumLength: 99999999999999999) { (data, _, _, error) in
			if let data = data, let message = String(data: data, encoding: .utf8) {
				
				// Handle PING request
				if message.contains("PING :") {
					let server = message.replacingOccurrences(of: "PING :", with: "")
					self.sendMessage("PONG :\(server)\r\n")
					print("Received Ping, Sent Pong")
				} else {
					DispatchQueue.main.async {
						let filteredMessages = self.processIRCMessage(message)
						for (nickname, messageContent) in filteredMessages {
							self.messages.append("\(nickname): \(messageContent)")
						}
					}
				}
			}
			
			if let error = error {
				print("Receive error: ", error)
			} else {
				self.setupReceive() // Continue receiving messages
			}
		}
	}
}
