import UIKit

final class ReviewsView: UIView {

    let tableView = UITableView()
    let refreshControl = UIRefreshControl()

    private let loadingView = LoadingView()

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds.inset(by: safeAreaInsets)
        loadingView.frame = tableView.frame
    }

    func setLoadingViewHidden(_ isHidden: Bool) {
        loadingView.isHidden = isHidden
    }

}

// MARK: - Private

private extension ReviewsView {

    func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupLoadingView()
    }

    func setupTableView() {
        addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
        tableView.register(ReviewsTotalCountCell.self, forCellReuseIdentifier: ReviewsTotalCountCellConfig.reuseId)
        tableView.refreshControl = refreshControl
    }

    func setupLoadingView() {
        addSubview(loadingView)
        loadingView.isHidden = true
    }

}

// MARK: - LoadingView

private extension ReviewsView {

    final class LoadingView: UIView {

        private let activityIndicator = UIActivityIndicatorView(style: .large)

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .systemBackground

            addSubview(activityIndicator)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

            activityIndicator.startAnimating()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}
