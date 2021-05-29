//
//  ContentView.swift
//  SwiftCombineExample
//
//  Created by Chris Brooks on 5/28/21.
//

import SwiftUI
import Combine

struct MovieCollectionView: View {
    
    @ObservedObject
    var movieViewModel: MovieCollectionViewModel
    
    var body: some View {
        Text("Hello, world!")
            .padding()
        
        List {
            ForEach(movieViewModel.movieList) { movie in
                MovieView(movie: movie)
            }
        }.onAppear() {
            movieViewModel.downloadMovieList()
        }
    }
}

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            return self.repeatForever(autoreverses: autoreverses)
        } else {
            return self
        }
    }
}

struct MovieView : View {
    
    let movie: Movie
    
    @ObservedObject
    var thumbnailDownloader: MovieThumbnailDownloader
    
    init(movie: Movie) {
        self.movie = movie
        
        thumbnailDownloader = MovieThumbnailDownloader()
        thumbnailDownloader.downloadMoviePosterThumbnail(movie: movie)
    }
    
    var body: some View {
        HStack {
            
            let uiImage = $thumbnailDownloader.image.wrappedValue ?? UIImage(named: "placeholder")
            
            let animation = Animation.default.repeat(while: $thumbnailDownloader.loading.wrappedValue)
            
            Image(uiImage: uiImage!)
                .resizable()
                .scaledToFit()
                .frame( minWidth: 45,
                        maxWidth: 45,
                        minHeight: 45,
                        maxHeight: 45,
                        alignment: .center)
                .scaleEffect($thumbnailDownloader.loading.wrappedValue ? 1.08: 1)
                .animation(animation)
                .onAppear() {
                    self.thumbnailDownloader.downloadMoviePosterThumbnail(movie: movie)
                }
            Text(movie.title)
        }
    }
}

struct MovieCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCollectionView(movieViewModel: MovieCollectionViewModel())
    }
}

class MovieCollectionViewModel: ObservableObject {
    
    @Published
    var movieList = [Movie]()
    
    func downloadMovieList() {
        let moviesUrl = URL(string: "https://raw.githubusercontent.com/meilisearch/MeiliSearch/main/datasets/movies/movies.json")
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        URLSession.shared.dataTaskPublisher(for: moviesUrl!)
            .map { $0.data }
            .decode(type: [Movie].self, decoder: jsonDecoder)
            .replaceError(with: [])
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: &$movieList)
    }
}

class MovieThumbnailDownloader: ObservableObject {
    
    @Published
    var image: UIImage?
    
    @Published
    var loading = false
    
    func downloadMoviePosterThumbnail(movie: Movie) {
        loading = true
        let thumbnailUrl = movie.poster
        let task = URLSession.shared.dataTask(with: thumbnailUrl) { [weak self]
            data, response, error in
            
            DispatchQueue.main.async {
                if let data = data {
                    self?.loading = false
                    self?.image = UIImage(data: data)
                }
            }
        }
        task.resume()
    }
}

/*{"id":"287947","title":"Shazam!","poster":"https://image.tmdb.org/t/p/w500/xnopI5Xtky18MPhK40cZAGAOVeV.jpg","overview":"A boy is given the ability to become an adult superhero in times of need with a single magic word.","release_date":1553299200,"genres":["Action","Comedy","Fantasy"]},*/
struct Movie: Codable, Identifiable {
    var id: String
    var title: String
    var poster: URL
    var overview: String
    var releaseDate: TimeInterval
    var genres: [String]?
}
