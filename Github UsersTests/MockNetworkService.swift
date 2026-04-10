//
//  MockNetworkService.swift
//  Github UsersTests
//
//  Created by Apple on 10/04/26.
//

import Testing
@testable import Github_Users

final class MockNetworkService: NetworkService {
    var result: Result<Data, Error>!

    func request<T>(_ req: URLRequest) async throws -> T where T : Decodable {
        switch result! {
        case .success(let data):
            return try JSONDecoder().decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

final class TestCoreDataStack {
    static func makeInMemory() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "GithubUsers")

        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType

        container.persistentStoreDescriptions = [desc]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Test CoreData error: \(error)")
            }
        }

        return container
    }
}

@Test
func githubUser_decoding() throws {
    let json = """
    {
        "id": 1,
        "login": "john",
        "avatar_url": "url"
    }
    """.data(using: .utf8)!

    let user = try JSONDecoder().decode(GithubUser.self, from: json)

    #expect(user.id == 1)
    #expect(user.login == "john")
    #expect(user.avatarUrl == "url")
}

@Test
func userEntity_toDomain() {
    let context = TestCoreDataStack.makeInMemory().viewContext

    let entity = UserEntity(context: context)
    entity.id = 10
    entity.login = "test"
    entity.avatarUrl = "img"

    let domain = entity.toDomain()

    #expect(domain.id == 10)
    #expect(domain.login == "test")
}

@Test
func localDataSource_upsert_and_fetch() throws {
    let container = TestCoreDataStack.makeInMemory()
    let context = container.viewContext

    let local = LocalUserDataSource(context: context)

    let users = [
        GithubUser(id: 1, login: "a", avatarUrl: "url1"),
        GithubUser(id: 2, login: "b", avatarUrl: "url2")
    ]

    local.upsert(users: users)

    let fetched = local.fetchUsers()

    #expect(fetched.count == 2)
}

// init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
//    self.context = context
// }

@Test
func network_decoding_success() async throws {
    let mock = MockNetworkService()

    let json = """
    [
        { "id": 1, "login": "john", "avatar_url": "url" }
    ]
    """.data(using: .utf8)!

    mock.result = .success(json)

    let req = URLRequest(url: URL(string: "https://test.com")!)
    let users: [GithubUser] = try await mock.request(req)

    #expect(users.count == 1)
}

@Test
func repository_returns_cache_immediately() async throws {
    let mockNetwork = MockNetworkService()
    let container = TestCoreDataStack.makeInMemory()

    let local = LocalUserDataSource(context: container.viewContext)

    // seed cache
    local.upsert(users: [
        GithubUser(id: 1, login: "cached", avatarUrl: "url")
    ])

    let repo = UserRepositoryImpl(network: mockNetwork, local: local)

    let result = try await repo.users(page: 0)

    #expect(result.first?.login == "cached")
}

final class MockRepo: UserRepository {
    func users(page: Int) async throws -> [GithubUser] {
        return [GithubUser(id: 1, login: "mock", avatarUrl: "url")]
    }
}

@Test
func useCase_executes_repo() async throws {
    let useCase = FetchUsersUseCase(repo: MockRepo())

    let result = try await useCase.execute(page: 0)

    #expect(result.count == 1)
}

@Test
@MainActor
func viewModel_load_success() async {
    let repo = MockRepo()
    let useCase = FetchUsersUseCase(repo: repo)

    let vm = UserListViewModel(useCase: useCase)

    vm.load()

    // wait for async
    try? await Task.sleep(nanoseconds: 300_000_000)

    #expect(vm.state == .loaded)
    #expect(vm.users.count == 1)
}

@Test
@MainActor
func viewModel_search_filters() async {
    let repo = MockRepo()
    let vm = UserListViewModel(useCase: FetchUsersUseCase(repo: repo))

    vm.users = [
        GithubUser(id: 1, login: "john", avatarUrl: ""),
        GithubUser(id: 2, login: "alice", avatarUrl: "")
    ]

    vm.search = "john"

    try? await Task.sleep(nanoseconds: 500_000_000)

    #expect(vm.users.count == 1)
}

@Test
func imageCache_store_and_get() {
    let cache = ImageCache.shared
    let img = UIImage()

    cache.set(img, key: "key")

    let retrieved = cache.get("key")

    #expect(retrieved != nil)
}


