//
//  CountriesList.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 24.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountriesList: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var countriesSearch = CountriesSearch()
    @State private var routingState: Routing = .init()
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.routing.countriesList)
    }
    let inspection = Inspection<Self>()
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                self.content
                    .navigationBarTitle("Repositories")
                    .navigationBarHidden(self.countriesSearch.keyboardHeight > 0)
                    .animation(.easeOut(duration: 0.3))
            }
            .modifier(NavigationViewStyle())
            .padding(.leading, self.leadingPadding(geometry))
        }
        .onAppear {
            //self.loadCountries("Swift")
            self.countriesSearch.onUpdate = {
                print($0)
                self.loadCountries($0)
            }
        }
        .onReceive(keyboardHeightUpdate) { self.countriesSearch.keyboardHeight = $0 }
        .onReceive(countriesUpdate) {
            self.countriesSearch.all = $0
            self.countriesSearch.filtered = $0
        }
        .onReceive(routingUpdate) { self.routingState = $0 }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    private var content: AnyView {
        switch countriesSearch.filtered {
        case .notRequested: return AnyView(notRequestedView)
        case let .isLoading(last, _): return AnyView(loadingView(last))
        case let .loaded(countries): return AnyView(loadedView(countries, showSearch: true))
        case let .failed(error): return AnyView(failedView(error))
        }
    }
    
    private func leadingPadding(_ geometry: GeometryProxy) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // A hack for correct display of the SplitView on iPads
            return geometry.size.width < geometry.size.height ? 0.5 : -0.5
        }
        return 0
    }
}

private extension CountriesList {
    struct NavigationViewStyle: ViewModifier {
        func body(content: Content) -> some View {
            #if targetEnvironment(macCatalyst)
            return content
            #else
            return content
                .navigationViewStyle(StackNavigationViewStyle())
            #endif
        }
    }
}

// MARK: - Side Effects

private extension CountriesList {
    func loadCountries(_ query: String) {
        injected.interactors.countriesInteractor
            .loadCountries(query: query)
    }
}

// MARK: - Loading Content

private extension CountriesList {
    var notRequestedView: some View {
        VStack {
            SearchBar(text: $countriesSearch.searchText)
            List([]) { country in
                NavigationLink(
                    destination: self.detailsView(country: country),
                    tag: country.id.description,
                    selection: self.routingBinding.countryDetails) {
                        CountryCell(repo: country)
                    }
            }
        }.padding(.bottom, self.countriesSearch.keyboardHeight)
    }
    
    func loadingView(_ previouslyLoaded: [GithubRepo]?) -> some View {
        VStack {
            SearchBar(text: $countriesSearch.searchText)
            ActivityIndicatorView().padding()
            (previouslyLoaded ?? []).map {
                loadedView($0, showSearch: false)
            }
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            self.loadCountries("Swift")
        })
    }
}

// MARK: - Displaying Content

private extension CountriesList {
    func loadedView(_ countries: [GithubRepo], showSearch: Bool) -> some View {
        VStack {
            if showSearch {
                SearchBar(text: $countriesSearch.searchText)
            }
            List(countries) { country in
                NavigationLink(
                    destination: self.detailsView(country: country),
                    tag: country.id.description,
                    selection: self.routingBinding.countryDetails) {
                        CountryCell(repo: country)
                    }
            }
        }.padding(.bottom, self.countriesSearch.keyboardHeight)
    }
    
    func detailsView(country: GithubRepo) -> some View {
        //CountryDetails(country: country)
        CountryDetails(repo: country)
    }
}

// MARK: - Filtering Countries

extension CountriesList {
    struct CountriesSearch {
        
        var onUpdate: ((String) -> Void)?
        var lastSearchText: String?
        
        var filtered: Loadable<[GithubRepo]> = .notRequested
        var all: Loadable<[GithubRepo]> = .notRequested {
            didSet { filterCountries() }
        }
        var searchText: String = "" {
            didSet { filterCountries() }
        }
        var keyboardHeight: CGFloat = 0
        var locale = Locale.current
        
        private mutating func filterCountries() {
            guard !searchText.isEmpty, lastSearchText != searchText else {
                return
            }
            
            onUpdate?(searchText)
            lastSearchText = searchText
            /*if searchText.count == 0 {
                filtered = all
            } else {
                filtered = all.map { countries in
                    countries.filter {
                        $0.id.description
                            .range(of: searchText, options: .caseInsensitive,
                                   range: nil, locale: nil) != nil
                    }
                }
            }*/
        }
    }
}

// MARK: - Routing

extension CountriesList {
    struct Routing: Equatable {
        var countryDetails: Country.Code?
    }
}

// MARK: - State Updates

private extension CountriesList {
    
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.routing.countriesList)
    }
    
    var countriesUpdate: AnyPublisher<Loadable<[GithubRepo]>, Never> {
        injected.appState.updates(for: \.userData.githubRepos)
    }
    
    var keyboardHeightUpdate: AnyPublisher<CGFloat, Never> {
        injected.appState.updates(for: \.system.keyboardHeight)
    }
}

#if DEBUG
struct CountriesList_Previews: PreviewProvider {
    static var previews: some View {
        CountriesList().inject(.preview)
    }
}
#endif
