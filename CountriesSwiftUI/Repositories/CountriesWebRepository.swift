//
//  CountriesWebRepository.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 29.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation

protocol CountriesWebRepository: WebRepository {
    func loadCountries() -> AnyPublisher<[Country], Error>
    func search(_ query: String) -> AnyPublisher<[GithubRepo], Error>
    func loadForks(repo: GithubRepo) -> AnyPublisher<[GithubRepo], Error>
    func loadCountryDetails(country: Country) -> AnyPublisher<Country.Details.Intermediate, Error>
}

struct RealCountriesWebRepository: CountriesWebRepository {
    
    let session: URLSession
    let baseURL: String
    let bgQueue = DispatchQueue(label: "bg_parse_queue")
    
    init(session: URLSession, baseURL: String) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func loadCountries() -> AnyPublisher<[Country], Error> {
        return call(endpoint: API.allCountries)
    }
    
    func search(_ query: String) -> AnyPublisher<[GithubRepo], Error> {
        let resp: AnyPublisher<GithubSearchResults, Error> = call(endpoint: API.search(query))
        return resp.tryMap { array -> [GithubRepo] in
            return array.items
        }.eraseToAnyPublisher()
    }
    
    func loadForks(repo: GithubRepo) -> AnyPublisher<[GithubRepo], Error> {
        call(endpoint: API.forks(repo.forks_url.replacingOccurrences(of: baseURL, with: "")))
        //.eraseToAnyPublisher()
    }

    func loadCountryDetails(country: Country) -> AnyPublisher<Country.Details.Intermediate, Error> {
        let request: AnyPublisher<[Country.Details.Intermediate], Error> = call(endpoint: API.countryDetails(country))
        return request
            .tryMap { array -> Country.Details.Intermediate in
                guard let details = array.first
                    else { throw APIError.unexpectedResponse }
                return details
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Endpoints

extension RealCountriesWebRepository {
    enum API {
        case allCountries
        case countryDetails(Country)
        case search(String)
        case forks(String)
    }
}

extension RealCountriesWebRepository.API: APICall {
    var path: String {
        switch self {
        case .allCountries:
            return "/all"
        case let .countryDetails(country):
            let encodedName = country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            return "/name/\(encodedName ?? country.name)"
        case let .search(query):
            return "/search/repositories?q=:\(query)&per_page=50"
        case let .forks(url):
            return url + "?per_page=50"
        }
    }
    var method: String {
        switch self {
        case .allCountries, .countryDetails, .search, .forks:
            return "GET"
        }
    }
    var headers: [String: String]? {
        return ["Accept": "application/json"]
    }
    func body() throws -> Data? {
        return nil
    }
}
