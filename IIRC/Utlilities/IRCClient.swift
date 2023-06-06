//
//  IRCClient.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//
import Foundation
import Network
import SwiftUI

extension Array: RawRepresentable where Element: Codable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
			  let result = try? JSONDecoder().decode([Element].self, from: data)
		else {
			return nil
		}
		self = result
	}
	
	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
			  let result = String(data: data, encoding: .utf8)
		else {
			return "[]"
		}
		return result
	}
}

class IRCClient : ObservableObject {
	// MARK: - Variables
	var connection : NWConnection?
	let queue = DispatchQueue(label: "IRC Queue")
	var serverHostname : String = ""
	var channel : String = ""
	var motdFinished : Bool = false
	var isConnected : Bool = false
	@AppStorage("Messages") var messages: [String] = []
	@AppStorage("Show Server Messages") var showServerMessages: Bool = false
	
	// MARK: - Connect
	func connect(host: String, port: UInt16, nickname: String, channel: String) {
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
	
	// MARK: - JoinChannel
	func joinChannel(nickname: String, channel: String) {
		sendMessage("NICK \(nickname)\r\n")
		sendMessage("USER \(nickname) 0 * :\(nickname)\r\n")
		sendMessage("JOIN #\(channel)\r\n")
		//pingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
		//	self.sendMessage("PING :irc\r\n")
		//}
	}
	
	// MARK: - sendMessage
	func sendMessage(_ message: String) {
		let data = message.data(using: .utf8)!
		connection?.send(content: data, completion: .contentProcessed({ error in
			if let error = error {
				print("Send error: ", error)
			}
		}))
	}
	
	// MARK: - SendChatMessage
	func sendChatMessage(_ message: String, to channel: String) {
		sendMessage("PRIVMSG #\(channel) :\(message)\r\n")
	}
	
	// MARK: - ProcessIRCMessage
	func processIRCMessage (_ message: String) -> [String] {
		let lines = message.components(separatedBy: "\r\n")
		var filteredMessages: [String] = []
		
		if (serverHostname == ""){
			serverHostname = (lines[0].dropLast(lines[0].distance(from: lines[0].dropFirst().firstIndex(of: " ") ?? lines[0].endIndex, to: lines[0].endIndex ))).dropFirst().lowercased()
		}
		//Update channel name after motd is finished
		if (channel == "" && motdFinished) {
			channel = String((lines[0].dropFirst(lines[0].distance(from: lines[0].startIndex, to: lines[0].dropFirst().firstIndex(of: "#") ?? lines[0].startIndex ))).dropFirst())
			channel = String(channel.dropLast(channel.distance(from: channel.firstIndex(of: " ") ?? channel.startIndex, to: channel.endIndex)))
		}
		
		// Handle PING request
		if message.contains("PING :") {
			//let server = message.replacingOccurrences(of: "PING :", with: "")
			self.sendMessage("PONG :\(serverHostname)\r\n")
			print("Received Ping, Sent Pong")
		} else {
			for line in lines {
				let temp = filter(line: line)
				// Dont show blank lines
				if temp != "" {
					filteredMessages.append(filter(line: line))
				}
			}
		}
		return filteredMessages
	}
	
	// MARK: - Filter
	// TODO: Add more edge cases, need to fix when user changes name and when a user joins
	func filter(line: String) -> String {
		var messageContent: String
		print(line) //DEBUG
		
		switch line {
				
			// MARK: - Server Connections
			case let str where (str.contains("NOTICE") || str.contains("001") || str.contains("002") || str.contains("003") || str.contains("004") || str.contains("005") || str.contains("251") || str.contains("252") || str.contains("253") || str.contains("254") || str.contains("255") || str.contains("265") || str.contains("266") || str.contains("250") || str.contains("250") || str.isEmpty):
				if (!isConnected) {
					isConnected = true
					messages.append("Connecting to Server...")
				}
				
				// Remove empty lines
				if str.isEmpty { return "" }
					
				// If toggled on in settings, show server connection messages
				if (showServerMessages){
					let nickname = "SERVER"
					messageContent = ("\(nickname): \(str.dropFirst(str.distance(from: str.startIndex, to: (str.dropFirst().firstIndex(of: ":") ?? str.startIndex))+1))")
					return messageContent
				}
				
				return ""
				
			// MARK: - User List
			// TODO: - Add user list view
			case let str where (str.contains("353")):
				let nickname = "Users"
				messageContent = ("\(nickname): \(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
				return messageContent
				
			// MARK: - Message of the Day
			case let str where (str.contains("375") || str.contains("372") || str.contains("332")):
				messageContent = ("\(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
				if (line.contains("332") && !motdFinished){
					motdFinished = true
					messages.append("Connecting to Channel...")
				}
				return messageContent
				
			// MARK: - User Group Message
			case let str where (str.contains("PRIVMSG")):
				let nickname = ("\((line.dropLast(line.distance(from: line.dropFirst().firstIndex(of: "!") ?? line.startIndex, to:  line.endIndex))).dropFirst())")
				messageContent = ("\(nickname): \((line.dropFirst(findSubstringIndex(string: line, substring: self.channel) ?? 0).dropFirst(channel.count + 2)))")
				//messageContent = line
				return messageContent
				
			// MARK: - Ignore List
			// TODO: - Add note of which users are admins
			case let str where (str.contains("333")/*Admin List*/ || str.contains("366")/*User END*/ || str.contains("376")/*MOTD END*/ || str.contains("328")):
				return ""
				
			//MARK: - Default
			default:
				if (motdFinished){
					return line
				}
				print("Line not shown: " + line) // DEBUG
				return ""
		}
	}
	
	// MARK: - FindSubstringIndex
	func findSubstringIndex(string: String, substring: String) -> Int? {
		if let range = string.range(of: substring) {
			return string.distance(from: string.startIndex, to: range.lowerBound)
		}
		return nil
	}
	
	//MARK: - SetupRecieve
	func setupReceive() {
		connection?.receive(minimumIncompleteLength: 1, maximumLength: 99999999999999999) { (data, _, _, error) in
			if let data = data, let message = String(data: data, encoding: .utf8) {
				DispatchQueue.main.async {
					let filteredMessages = self.processIRCMessage(message)
					for messageContent in filteredMessages {
						self.messages.append("\(messageContent)")
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
