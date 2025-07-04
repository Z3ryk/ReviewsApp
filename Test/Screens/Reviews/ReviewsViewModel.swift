import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((ViewState) -> Void)?

    var hasContent: Bool { state.items.isEmpty == false }

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState
    typealias ViewState = ReviewsViewState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        onStateChange?(.loading)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }

            reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
        }
    }

    /// Метод повторной загрузки отзывов
    func refreshReviews() {
        state.offset = 0
        state.shouldLoad = true

        getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            let items = reviews.items.map(makeReviewItem)
            if state.offset == .zero {
                state.items = items
            } else {
                state.items += items
            }
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count

            if !state.shouldLoad {
                state.items.append(makeReviewsTotalCountItem(reviewsCount: reviews.count))
            }
        } catch {
            state.shouldLoad = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                onStateChange?(.error)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            onStateChange?(.content)
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(.content)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let fullName = "\(review.firstName) \(review.lastName)"
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let ratingImage = ratingRenderer.ratingImage(review.rating)
        let item = ReviewItem(
            reviewText: reviewText,
            created: created,
            userName: fullName,
            ratingImage: ratingImage,
            avatarUrl: review.avatarUrl,
            photos: review.photos,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            }
        )
        return item
    }

    typealias ReviewsTotalCountItem = ReviewsTotalCountCellConfig

    func makeReviewsTotalCountItem(reviewsCount: UInt) -> ReviewsTotalCountItem {
        ReviewsTotalCountItem(text: "\(reviewsCount) отзывов")
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
