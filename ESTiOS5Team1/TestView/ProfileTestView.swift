//
//  ProfileTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//


 import SwiftUI

  struct ProfileTestView: View {
      @StateObject private var vm = ProfileViewModel()

      var body: some View {
          VStack(spacing: 16) {
              Text("Profile Test")
                  .font(.title2)

              TextField("nickname", text: $vm.nickname)
                  .textFieldStyle(.roundedBorder)

              TextField("avatarUrl", text: $vm.avatarUrl)
                  .textFieldStyle(.roundedBorder)

              HStack(spacing: 12) {
                  Button("Create") {
                      Task { await vm.createProfile() }
                  }
                  Button("Get") {
                      Task { await vm.fetchProfile() }
                  }
                  Button("Update") {
                      Task { await vm.updateProfile() }
                  }
              }

              Button("Presign") {
                  Task {
                      _ = await vm.presign(filename: "avatar.png", expiresIn: 900)
                  }
              }

              if let profile = vm.profile {
                  Text("id: \(profile.id)")
                  Text("userId: \(profile.userId)")
                  Text("nickname: \(profile.nickname)")
                  Text("avatarUrl: \(profile.avatarUrl)")
              }

              if !vm.errorMessage.isEmpty {
                  Text(vm.errorMessage)
                      .foregroundColor(.red)
              }
          }
          .padding()
      }
  }

  #Preview {
      ProfileTestView()
  }
