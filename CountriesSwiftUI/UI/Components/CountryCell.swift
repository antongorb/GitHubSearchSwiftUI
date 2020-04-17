//
//  CountryCell.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 25.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI

struct CountryCell: View {
    
    let repo: GithubRepo
    @Environment(\.locale) var locale: Locale
    
    var body: some View {
        HStack {
            flagView(url: URL(string: repo.owner.avatar_url)!).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.title)
                Text(repo.description)
                    .font(.caption)
                if repo.forks > 0 {
                    Text("Forks: \(repo.forks.description)")
                        .font(.caption)
                }
            }
        }
            //.padding()
            .frame(maxWidth: .infinity, maxHeight: 60, alignment: .leading)
    }
    
    func flagView(url: URL) -> some View {
        //HStack {
        //Spacer()
        SVGImageView(imageURL: url)
            .frame(width: 40, height: 40)
        //Spacer()
        //}
    }
}

#if DEBUG
struct CountryCell_Previews: PreviewProvider {
    static var previews: some View {
        CountryCell(repo: GithubRepo.mockedData[0])
            .previewLayout(.fixed(width: 375, height: 60))
    }
}
#endif
