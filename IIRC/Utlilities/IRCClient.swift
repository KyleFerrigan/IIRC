//
//  IRCClient.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//
import Foundation
import Network

class IRCClient : ObservableObject {
	// MARK: - Variables
	var connection : NWConnection?
	let queue = DispatchQueue(label: "IRC Queue")
	var hostStr : String = ""
	var serverHostname : String = ""
	var channel : String = ""
	var motdFinished : Bool = false
	var isConnected : Bool = false
	@Published var messages : [String] = []
	
	// MARK: - Connect
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
		if (channel == "" && motdFinished) {
			channel = (lines[0].dropFirst(lines[0].distance(from: lines[0].startIndex, to: lines[0].dropFirst().firstIndex(of: "#") ?? lines[0].startIndex ))).dropFirst().lowercased()
		}
		
		// Handle PING request
		if message.contains("PING :") {
			//let server = message.replacingOccurrences(of: "PING :", with: "")
			self.sendMessage("PONG :\(serverHostname)\r\n")
			print("Received Ping, Sent Pong")
		} else {
			for line in lines {
				var temp = filter(line: line)
				// Dont show blank lines
				if temp != "" {
					filteredMessages.append(filter(line: line))
				}
			}
		}
		return filteredMessages
	}
	
	// MARK: - Filter
	func filter(line: String) -> String {
		var messageContent: String
		print(line) //DEBUG
		
		switch line {
				
			// MARK: - Server Connections, Ignore for now.
			// TODO: - Add toggle in settings for if user wants to see server messages
			case let str where (str.contains("NOTICE") || str.contains("001") || str.contains("002") || str.contains("003") || str.contains("004") || str.contains("005") || str.contains("251") || str.contains("252") || str.contains("253") || str.contains("254") || str.contains("255") || str.contains("265") || str.contains("266") || str.contains("250") || str.contains("250") || str.isEmpty):
				if (!isConnected) {
					isConnected = true
					messages.append("Connecting...")
				}
				/* Uncomment this block to show server messages
				
				let nickname = "SERVER"
				messageContent = ("\(nickname): \(line)") //line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1) */
				return ""
				
			// MARK: - Admin List, End of Names Message, & End of MOTD Message. Ignore for now
			// TODO: - Add note of which users are admins
			case let str where (str.contains("333")/*Admin List*/ || str.contains("366")/*User END*/ || str.contains("376")/*MOTD END*/):
				return ""
				
			// MARK: - User List
			// TODO: - Add user list view
			case let str where (str.contains("353")):
				let nickname = "Users"
				messageContent = ("\(nickname): \(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
				return messageContent
				
			// MARK: - Message of the Day
			// TODO: - Remove "End of /MOTD command."
			case let str where (str.contains("375") || str.contains("372") || str.contains("332")):
				messageContent = ("\(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
				if line.contains("332"){
					motdFinished = true
				}
				return messageContent
				
			// MARK: - User Group Message
			// TODO: URGENT! Fix message content
			case let str where (str.contains("PRIVMSG")):
				let nickname = ("\((line.dropLast(line.distance(from: line.dropFirst().firstIndex(of: "!") ?? line.startIndex, to:  line.endIndex))).dropFirst())")
				messageContent = ("\(nickname): \((line.dropFirst(findSubstringIndex(string: line, substring: self.channel) ?? 0))))")
				//messageContent = line
				return messageContent
				
			//MARK: - Default
			default:
				if (motdFinished){
					return line
				}
				print("Line not shown: " + line) // DEBUG
				return ""
				
		}
		/*
		if (line.contains("NOTICE")||line.contains("001")||line.contains("002")||line.contains("003")||line.contains("004")||line.contains("005")||line.contains("251")||line.contains("252")||line.contains("253")||line.contains("254")||line.contains("255")||line.contains("265")||line.contains("266")||line.contains("250")||line.isEmpty
		) { //Server Connection Messages: Drop them, user does not need to see them
			if (!isConnected) {
				isConnected = true
				messages.append("Connecting...")
			}
			//let nickname = "SERVER"
			//messageContent = ("\(nickname): \(line)") //line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1)
			return ""
		} else if (line.contains("333") || line.contains("366")){// Ignore, Admin List and End of Names list message
			return ""
		} else if (line.contains("353")){ // Users
			let nickname = "Users"
			messageContent = ("\(nickname): \(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
			return messageContent
		} else if (line.contains("375")||line.contains("372") || line.contains("376") || line.contains("332")){ //Message of the Day
			messageContent = ("\(line.dropFirst(line.distance(from: line.startIndex, to: (line.dropFirst().firstIndex(of: ":") ?? line.startIndex))+1))")
			if line.contains("332"){
				motdFinished = true
			}
			return messageContent
		} else if (line.contains("MODE")){ //mode
			//let nickname = "MODE"
			//messageContent = ("\(nickname): \(line)")
			//filteredMessages.append((messageContent))
			return ""
		} else if (line.contains("PRIVMSG")) { //User Messages
			// Extract the nickname
			let nickname = ("\((line.dropLast(line.distance(from: line.dropFirst().firstIndex(of: "!") ?? line.startIndex, to:  line.endIndex))).dropFirst())")
			messageContent = ("\(nickname): \((line.dropFirst(findSubstringIndex(string: line, substring: self.channel) ?? 0))))")
			//messageContent = line
			// Append the filtered message to the result
			return messageContent
		} else { //Unknown, dont filter
			// Append the unfiltered message to the result
			return line
		}
		 */
		
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
