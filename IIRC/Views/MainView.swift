//
//  ContentView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//

import SwiftUI

struct MainView: View {
	// Vars
	@StateObject private var client = IRCClient()
	#if DEBUG
	@State private var server = "irc.libera.chat"
	@State private var port = "6667"
	@State private var nickname = "iOSAppTest"
	@State private var channel = "textual-testing"
	#else
	@State private var server = ""
	@State private var port = ""
	@State private var nickname = ""
	@State private var channel = ""
	#endif
	
	@State private var isConnected = false
	
	var body: some View {
		NavigationView{
			NavigationStack{
				ConnectView(server: self.$server, port: self.$port, nickname: self.$nickname, channel: self.$channel, isConnected: self.$isConnected, client: self.client)
				
				NavigationLink(
					destination: ChatView(client: client, channel: channel, nickname: nickname)
						.onDisappear (perform: disconnect)
					,
					isActive: $isConnected,
					label: { EmptyView() }
				)
				.hidden()
			}
			.navigationTitle("IIRC")
			.navigationBarTitleDisplayMode(.inline)
		}
		
	}
	
	func disconnect() {
		client.connection?.cancel() // Close the connection
		client.connection = nil // Set the connection to nil
		isConnected = false
	}
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
