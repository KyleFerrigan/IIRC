//
//  ContentView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//

import SwiftUI

struct MainView: View {
	@StateObject private var client = IRCClient()
	@State private var server = ""
	@State private var port = ""
	@State private var nickname = ""
	@State private var channel = ""
	@State private var isConnected = false
	
	var body: some View {
		NavigationStack{
			ConnectView(server: self.$server, port: self.$port, nickname: self.$nickname, channel: self.$channel, isConnected: self.$isConnected, client: self.client)
			NavigationLink(
				destination: ChatView(client: client, channel: channel)
					.onDisappear (perform: disconnect)
				,
				isActive: $isConnected,
				label: { EmptyView() }
			)
			.hidden()
		}
		.navigationBarTitle("IIRC",displayMode: .inline)
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
