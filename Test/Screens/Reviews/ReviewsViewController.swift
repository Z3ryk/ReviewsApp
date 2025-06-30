import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        reviewsView.refreshControl.addTarget(
            self,
            action: #selector(didPullToRefreshReviews),
            for: .valueChanged
        )
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsView, weak viewModel] viewState in
            switch viewState {
            case .loading:
                guard viewModel?.hasContent == false else { return }

                reviewsView?.setLoadingViewHidden(false)
            case .content:
                reviewsView?.refreshControl.endRefreshing()
                reviewsView?.tableView.reloadData()
                reviewsView?.setLoadingViewHidden(true)
            case .error:
                reviewsView?.setLoadingViewHidden(true)
            }
        }
    }

    @objc
    func didPullToRefreshReviews() {
        viewModel.refreshReviews()
    }

}
