//
//  MockedModel.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 27.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation

#if DEBUG

extension Country {
    static let mockedData: [Country] = [
        Country(name: "United States", translations: [:], population: 125000000,
                flag: URL(string: "https://restcountries.eu/data/usa.svg"), alpha3Code: "USA"),
        Country(name: "Georgia", translations: [:], population: 2340000, flag: nil, alpha3Code: "GEO"),
        Country(name: "Canada", translations: [:], population: 57600000, flag: nil, alpha3Code: "CAN")
    ]
}

extension GithubRepo {
    static let mockedData: [GithubRepo] = [
        GithubRepo(id: 100500, name: "test", description: "desc", forks: 100, watchers: 120, owner: Owner(id: 1, avatar_url: "https://avatars3.githubusercontent.com/u/13662162?v=4", login: "test"), forks_url: "https://api.github.com/repos/Moya/Moya/forks")
    ]
}

extension Country.Details {
    static var mockedData: [Country.Details] = {
        let neighbors = Country.mockedData
        return [
            Country.Details(capital: "Sin City", currencies: Country.Currency.mockedData, neighbors: neighbors),
            Country.Details(capital: "Los Angeles", currencies: Country.Currency.mockedData, neighbors: []),
            Country.Details(capital: "New York", currencies: [], neighbors: []),
            Country.Details(capital: "Moscow", currencies: [], neighbors: neighbors)
        ]
    }()
}

extension Country.Currency {
    static let mockedData: [Country.Currency] = [
        Country.Currency(code: "USD", symbol: "$", name: "US Dollar"),
        Country.Currency(code: "EUR", symbol: "€", name: "Euro"),
        Country.Currency(code: "RUB", symbol: "‡", name: "Rouble")
    ]
}

#endif
