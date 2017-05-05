//
//  ViewController.swift
//  GithubAPI+RxSwift
//
//  Created by KumagaiNaoki on 2017/05/05.
//  Copyright © 2017年 KumagaiNaoki. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

struct SearchResult {
    let repos: [GithubRepository]
    let totalCount: Int
    init?(response: Any) {
        guard let response = response as? [String: Any],
            let reposDictionaries = response["items"] as? [[String: Any]],
            let count = response["total_count"] as? Int
            else { return nil }
        //flatMapは一個ずつ取り出してある型に変換する。変換できないものはnilで取り除かれる。
        repos = reposDictionaries.flatMap{ GithubRepository(dictionary: $0) }
        totalCount = count
    }
}

struct GithubRepository {
    let name: String
    let startCount: Int
    init(dictionary: [String: Any]) {
        name = dictionary["full_name"] as! String
        startCount = dictionary["stargazers_count"] as! Int
    }
}

class ViewController: UIViewController {
    
    let searchField = UITextField()
    let totalCountLabel = UILabel()
    let reposLabel = UILabel()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
        bind()
    }
    
    private func searchRepos(keyword: String) -> Observable<SearchResult?> {
        let endPoint = "https://api.github.com"
        let path = "/search/repositories"
        let query = "?q=\(keyword)"
        let stringURL = endPoint + path + query
        let url = URL(string: stringURL)!
        let request = URLRequest(url: url)
        return URLSession.shared
            .rx.json(request: request)
            .map{ SearchResult(response: $0) }
    }
    
    private func bind() {
        let result: Observable<SearchResult?> = searchField.rx.text
            .orEmpty
            .asObservable()
            .skip(1)
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest {
                self.searchRepos(keyword: $0)
                    .observeOn(MainScheduler.instance)
                    .catchErrorJustReturn(nil)
            }
            .shareReplay(1)
        
        let foundRepos: Observable<String> = result.map {
            let repos = $0?.repos ?? [GithubRepository]()
            return repos.reduce("") {
                $0 + "\($1.name)(\($1.startCount))\n"
            }
        }
        
        let foundCount: Observable<String> = result.map {
            let count = $0?.totalCount ?? 0
            return "TotalCount: \(count)"
        }
        
        foundRepos
            .bindTo(reposLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        foundCount
            .startWith("Input Repository Name")
            .bindTo(totalCountLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    private func setupSubViews() {
        view.backgroundColor = UIColor.white
        searchField.frame = CGRect(x: 10, y: 10, width: 300, height: 20)
        totalCountLabel.frame = CGRect(x: 10, y: 40, width: 300, height: 20)
        reposLabel.frame = CGRect(x: 10, y: 60, width: 300, height: 400)
        searchField.backgroundColor = UIColor.brown
        totalCountLabel.backgroundColor = UIColor.darkGray
        reposLabel.backgroundColor = UIColor.green
        searchField.borderStyle = .roundedRect
        reposLabel.numberOfLines = 0
        searchField.keyboardType = .alphabet
        
        view.addSubview(searchField)
        view.addSubview(totalCountLabel)
        view.addSubview(reposLabel)
    }

}

