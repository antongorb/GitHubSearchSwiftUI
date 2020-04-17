//
//  ForkRow.swift
//  CountriesSwiftUI
//
//  Created by Anthony Gorb on 19.03.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import SwiftUI

struct ForkRow: View {
    
    let repo: GithubRepo
    
    var body: some View {
        HStack {
            flagView(url: URL(string: repo.owner.avatar_url)!).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(repo.owner.login)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 60, alignment: .leading)
    }
    
    func flagView(url: URL) -> some View {
        SVGImageView(imageURL: url)
            .frame(width: 40, height: 40)
    }
}

#if DEBUG
struct ForkRow_Previews: PreviewProvider {
    static var previews: some View {
        ForkRow(repo: GithubRepo.mockedData[0])
            .previewLayout(.fixed(width: 375, height: 60))
    }
}
#endif
