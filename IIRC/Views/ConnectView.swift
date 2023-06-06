//
//  ConnectView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-12.
//

import SwiftUI

//Allow chat history array to be stored in @AppStorage


struct ConnectView: View {
	
	// MARK: - Variables
	@StateObject var client = IRCClient()
	@AppStorage("Keep Chat History") var keepChatHistory: Bool = false
	@AppStorage("Default Nickname") var defaultNickname: String = ""
	
	#if DEBUG
	@State private var server = "irc.libera.chat"
	@State private var port = "6667"
	@State private var nickname = "Dev-Test"
	@State private var channel = "textual-testing"
	@State var isFormFilled = true
	#else
	@State private var server = ""
	@State private var port = ""
	@State private var nickname = self.defaultNickname
	@State private var channel = ""
	@State var isFormFilled = false
	#endif
	
    var body: some View {
		List{
			Section(header: Text("Manual Connection")) {
				TextField("Server", text: $server)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.onChange(of: server) { _ in updateFormFilled() }
				
				TextField("Port", text: $port)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.keyboardType(.numberPad)
					.onChange(of: port) { _ in updateFormFilled() }
				
				TextField("Nickname", text: $nickname)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.onChange(of: nickname) { _ in updateFormFilled() }
				
				TextField("Channel", text: $channel)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.onChange(of: channel) { _ in updateFormFilled() }
				
				NavigationLink("Connect", destination: ChatView(client: client, channel: channel, nickname: nickname).onAppear(perform: connect).onDisappear(perform: disconnect))
					.foregroundColor(self.isFormFilled ? .blue : .gray)
					.disabled(!self.isFormFilled)
					
			}
			
			// TODO: - Add these recent and favorite features in
			
			//Section(header: Text("Recent Servers")) {
			//}
			
			//Section(header: Text("Favorite Servers")) {
			//}
		}
		
    }
	
	// MARK: - UpdateFormFilled
	private func updateFormFilled() {
		print("UpdateFormFilled Function Ran")
		isFormFilled = !server.isEmpty && !port.isEmpty && !nickname.isEmpty && !channel.isEmpty
	}
	
	// MARK: - Connect
	func connect() {
		print("Connect Function Ran")
		guard let portUInt = UInt16(port) else { return }
		client.connect(host: server, port: portUInt, nickname: nickname, channel: channel)
	}
	
	// MARK: - Disconnect
	func disconnect() {
		print("Disconnect Function Ran")
		//Set all values back to normal
		client.connection?.cancel() // Close the connection
		client.connection = nil // Set the connection to nil
		client.serverHostname = ""
		client.channel = ""
		client.motdFinished = false
		client.isConnected = false
		
		
		
		if (!keepChatHistory){
			client.messages = []
		}
	}
}

// MARK: - Preview
struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
		ConnectView(client: IRCClient())
    }
}
