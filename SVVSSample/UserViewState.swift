//
//  UserViewState.swift
//  SVVSSample
//
//  Created by Yuta Koshizawa on 2023/08/15.
//

import Combine
import OrderedCollections

@MainActor
final class UserViewState: ObservableObject {
    let id: User.ID

    @Published private(set) var user: User?
    @Published private(set) var friends: OrderedDictionary<User.ID, User> = [:]

    @Published var showsOnlyBookmarkedFriends: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(id: User.ID) {
        self.id = id

        UserStore.shared.$values.map { $0[id] }.removeDuplicates().assign(to: &$user)

        $user.combineLatest(UserStore.shared.$values).map { user, users in
            guard let user else { return [:] }
            return OrderedDictionary(
                uniqueKeysWithValues: user.friendIDs.lazy
                    .compactMap { friendID in users[friendID] }
                    .map { user in (user.id, user) }
            )
        }
        .removeDuplicates()
        .assign(to: &$friends)

        $user.sink { user in
            guard let user else { return }
            Task {
                do {
                    try await UserStore.shared.loadValues(for: user.friendIDs)
                } catch {
                    // TODO: Error Handling
                    print(error)
                }
            }
        }
        .store(in: &cancellables)
    }

    func onAppear() async {
        do {
            try await UserStore.shared.loadValue(for: id)
        } catch {
            // TODO: Error Handling
            print(error)
        }
    }

    func toggleFriendBookmark(for id: User.ID) async {
        guard var friend = friends[id] else { return }
        friend.isBookmarked.toggle()
        friends[id] = friend // to apply changes to views immediately
        do {
            try await UserStore.shared.updateBookmarked(friend.isBookmarked, for: id)
        } catch {
            friends[id] = UserStore.shared.values[id] // resets changes
            // TODO: Error Handling
            print(error)
        }
    }
}
