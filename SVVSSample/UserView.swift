//
//  UserView.swift
//  SVVSSample
//
//  Created by Yuta Koshizawa on 2023/08/15.
//

import SwiftUI

struct UserView: View {
    @StateObject private var state: UserViewState

    @State private var navigatesToFriendView: Set<User.ID> = []

    init(id: User.ID) {
        self._state = .init(wrappedValue: .init(id: id))
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 60)

                    if let user = state.user {
                        Text(user.name)
                            .font(.title)
                    } else {
                        Text("User Name")
                            .font(.title)
                            .redacted(reason: .placeholder)
                    }
                }
                VStack {
                    Text("Friends")
                        .font(.headline)
                    Toggle("Only bookmarked", isOn: $state.showsOnlyBookmarkedFriends)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        Divider()
                        ForEach(state.friends.values) { friend in
                            NavigationLink {
                                UserView(id: friend.id)
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                        .frame(width: 40, height: 40)
                                    Text(friend.name)
                                        .font(.title2)
                                    Spacer()
                                    Button {
                                        Task {
                                            await state.toggleFriendBookmark(for: friend.id)
                                        }
                                    } label: {
                                        Image(systemName: friend.isBookmarked ? "bookmark.fill" : "bookmark")
                                    }
                                    Image(systemName: "chevron.forward")
                                }
                                .padding()
                                // Hack to change a cell color when selected
                                .background(
                                    Color(uiColor: .systemBackground)
                                        .background(Color.gray)
                                )
                            }
                            .buttonStyle(.plain)

                            Divider()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .task {
            await state.onAppear()
        }
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(id: "A")
    }
}
