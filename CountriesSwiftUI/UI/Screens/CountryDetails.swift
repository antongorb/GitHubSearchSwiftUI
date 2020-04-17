//
//  CountryDetails.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 25.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountryDetails: View {
    
    let repo: GithubRepo
    
    @Environment(\.locale) var locale: Locale
    @Environment(\.injected) private var injected: DIContainer
    @State private var details: Loadable<GithubRepo>
    @State private var forks: Loadable<[GithubRepo]>
    @State private var routingState: Routing = .init()
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.routing.countryDetails)
    }
    let inspection = Inspection<Self>()
    
    init(repo: GithubRepo, details: Loadable<GithubRepo> = .notRequested, forks: Loadable<[GithubRepo]> = .notRequested) {
        self.repo = repo
        self._details = .init(initialValue: details)
        self._forks = .init(initialValue: forks)
    }
    
    var body: some View {
        content
            .navigationBarTitle(repo.name)
            .modifier(NavigationBarBugFixer(goBack: self.goBack))
            .onReceive(routingUpdate) { self.routingState = $0 }
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    private var content: AnyView {
        switch details {
        case .notRequested: return AnyView(notRequestedView)
        case .isLoading: return AnyView(loadingView)
        case let .loaded(countryDetails): return AnyView(loadedView(countryDetails))
        case let .failed(error): return AnyView(failedView(error))
        }
    }
}

// MARK: - Side Effects

private extension CountryDetails {
    func loadCountryDetails() {
        details = Loadable.loaded(repo)
        injected.interactors.countriesInteractor.loadForks(repoBind: $forks, repo: repo)
            //.load(countryDetails: $details, repo: repo)
    }
    
    func showCountryDetailsSheet() {
        injected.appState[\.routing.countryDetails.detailsSheet] = true
    }
    
    func goBack() {
        injected.appState[\.routing.countriesList.countryDetails] = nil
    }
}

// MARK: - Loading Content

private extension CountryDetails {
    var notRequestedView: some View {
        Text("").onAppear {
            self.loadCountryDetails()
        }
    }
    
    var loadingView: some View {
        VStack {
            ActivityIndicatorView()
            Button(action: {
                self.details.cancelLoading()
            }, label: { Text("Cancel loading") })
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            self.loadCountryDetails()
        })
    }
}

// MARK: - A workaround for a bug in NavigationBar
// https://stackoverflow.com/q/58404725/2923345

private struct NavigationBarBugFixer: ViewModifier {
        
    let goBack: () -> Void
    
    func body(content: Content) -> some View {
        #if targetEnvironment(simulator)
        let isiPhoneSimulator = UIDevice.current.userInterfaceIdiom == .phone
        return Group {
            if ProcessInfo.processInfo.isRunningTests {
                content
            } else {
                content
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(leading: Button(action: {
                        print("Please note that NavigationView currently does not work correctly on the iOS Simulator.")
                        self.goBack()
                    }, label: { Text(isiPhoneSimulator ? "Back" : "") }))
            }
        }
        #else
        return content
        #endif
    }
}

// MARK: - Displaying Content

private extension CountryDetails {
    func loadedView(_ repo: GithubRepo) -> some View {
        List {
            flagView(url: URL(string: repo.owner.avatar_url)!).clipShape(Circle())
            basicInfoSectionView(repo: repo)
            if repo.forks > 0 {
                currenciesSectionView(forks: forks.value ?? [])
            }
            //if countryDetails.neighbors.count > 0 {
            //    neighborsSectionView(neighbors: countryDetails.neighbors)
            //}
        }
        .listStyle(GroupedListStyle())
        .sheet(isPresented: routingBinding.detailsSheet,
               content: { self.modalDetailsView() })
    }
    
    func flagView(url: URL) -> some View {
        HStack {
            Spacer()
            SVGImageView(imageURL: url)
                .frame(width: 120, height: 80)
                .onTapGesture {
                    self.showCountryDetailsSheet()
                }
            Spacer()
        }
    }
    
    func basicInfoSectionView(repo: GithubRepo) -> some View {
        Section(header: Text("Repo Info")) {
            DetailRow(leftLabel: "Name", rightLabel: Text(repo.name))
            DetailRow(leftLabel: "Owner login", rightLabel: Text(repo.owner.login))
            DetailRow(leftLabel: "Watchers", rightLabel: Text(repo.watchers.description))
        }
    }
    
    func currenciesSectionView(forks: [GithubRepo]) -> some View {
        Section(header: Text("Fork owners")) {
            ForEach(forks) { fork in
                ForkRow(repo: fork)
            }
        }
    }
    
    func neighborsSectionView(neighbors: [Country]) -> some View {
        Section(header: Text("Neighboring countries")) {
            ForEach(neighbors) { country in
                NavigationLink(destination: self.neighbourDetailsView(country: country)) {
                    DetailRow(leftLabel: Text(country.name(locale: self.locale)), rightLabel: Text("test"))
                }
            }
        }
    }
    
    func neighbourDetailsView(country: Country) -> some View {
        CountryDetails(repo: repo)
    }
    
    func modalDetailsView() -> some View {
        ModalDetailsView(repo: repo,
                         isDisplayed: routingBinding.detailsSheet)
            .inject(injected)
    }
}

// MARK: - Helpers

private extension Country.Currency {
    var title: String {
        return name + (symbol.map {" " + $0} ?? "")
    }
}

// MARK: - Routing

extension CountryDetails {
    struct Routing: Equatable {
        var detailsSheet: Bool = false
    }
}

// MARK: - State Updates

private extension CountryDetails {
    
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.routing.countryDetails)
    }
}

// MARK: - Preview

#if DEBUG
struct CountryDetails_Previews: PreviewProvider {
    static var previews: some View {
        CountryDetails(repo: GithubRepo.mockedData[0])
            .inject(.preview)
    }
}
#endif
