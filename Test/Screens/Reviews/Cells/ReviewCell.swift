import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Полное имя пользователя
    let userName: String
    /// Изображение рейтинг отзыва
    let ratingImage: UIImage
    /// Ссылка на аватар пользователя
    let avatarUrl: URL?
    /// Названия фотографий
    let photos: [String]?
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }

        cell.userNameLabel.text = userName
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.config = self
        cell.setRatingImage(ratingImage)
        photos.map(cell.addPhotos)

        cell.avatarLoadingTask?.cancel()
        cell.avatarLoadingTask = Task {
            if
                let avatarUrl,
                Task.isCancelled == false,
                let image = await ImageLoader.shared.image(for: avatarUrl)
            {
                await MainActor.run {
                    guard cell.config?.id == self.id else { return }

                    cell.avatarImageView.image = image
                }
            }
        }
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    fileprivate let avatarImageView = UIImageView()
    fileprivate let userNameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let photosStackView = UIStackView()
    fileprivate let photosScrollView = UIScrollView()

    fileprivate var avatarLoadingTask: Task<Void, Never>?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let layout = config?.layout else { return }

        avatarImageView.frame = layout.avatarImageFrame
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        userNameLabel.frame = layout.userNameLabelFrame
        ratingImageView.frame = layout.ratingImageFrame
        photosStackView.frame = layout.photosStackViewFrame
        photosScrollView.frame = layout.photosScrollViewFrame
        photosScrollView.contentSize = layout.photosStackViewFrame.size
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarLoadingTask?.cancel()
        avatarImageView.image = .l5W5AIHioYc

        reviewTextLabel.attributedText = nil
        reviewTextLabel.numberOfLines = 1
        createdLabel.attributedText = nil
        userNameLabel.text = nil
        ratingImageView.image = nil
        config = nil
        photosStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }

}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImageView()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupUserNameLabel()
        setupRatingImageView()
        setupPhotosScrollView()
        setupPhotosStackView()
    }

    func setupAvatarImageView() {
        contentView.addSubview(avatarImageView)
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
        avatarImageView.image = .l5W5AIHioYc
    }

    func setupUserNameLabel() {
        contentView.addSubview(userNameLabel)
        userNameLabel.font = .username
        userNameLabel.textColor = .label
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(
            self,
            action: #selector(showMoreTapped),
            for: .touchUpInside
        )
    }

    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .left
    }

    func setupPhotosScrollView() {
        contentView.addSubview(photosScrollView)
        photosScrollView.showsHorizontalScrollIndicator = false
        photosScrollView.showsHorizontalScrollIndicator = false
    }

    func setupPhotosStackView() {
        photosScrollView.addSubview(photosStackView)
        photosStackView.axis = .horizontal
        photosStackView.alignment = .fill
        photosStackView.distribution = .fillEqually
        photosStackView.spacing = 8.0
    }

    func addPhotos(_ photos: [String]) {
        for photo in photos {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = Layout.photoCornerRadius
            imageView.image = UIImage(named: photo)
            photosStackView.addArrangedSubview(imageView)
        }
    }

    func setRatingImage(_ ratingImage: UIImage) {
        ratingImageView.image = ratingImage
    }

    @objc
    func showMoreTapped() {
        guard let config else { return }

        config.onTapShowMore(config.id)
    }

}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы

    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var avatarImageFrame = CGRect.zero
    private(set) var userNameLabelFrame = CGRect.zero
    private(set) var ratingImageFrame = CGRect.zero
    private(set) var photosStackViewFrame = CGRect.zero
    private(set) var photosScrollViewFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let textOriginX = insets.left + Self.avatarSize.width + avatarToUsernameSpacing
        let width = maxWidth - textOriginX - insets.right

        var maxY = insets.top
        var showShowMoreButton = false

        let hasPhotos = config.photos?.isEmpty == false

        avatarImageFrame = CGRect (
            origin: CGPoint(x: insets.left, y: insets.top),
            size: Layout.avatarSize
        )

        userNameLabelFrame = CGRect(
            origin: CGPoint(x: textOriginX, y: maxY),
            size: CGSize(width: width, height: 18)
        )
        maxY = userNameLabelFrame.maxY + usernameToRatingSpacing

        ratingImageFrame = CGRect(
            origin: CGPoint(x: textOriginX, y: maxY),
            size: CGSize(width: 80, height: 16)
        )
        maxY = ratingImageFrame.maxY + (!hasPhotos ? ratingToTextSpacing : ratingToPhotosSpacing)

        if hasPhotos, let count = config.photos?.count {
            let photosCount = CGFloat(count)
            let photosWidth = (Layout.photoSize.width * photosCount) + (photosSpacing * (photosCount - 1))
            photosScrollViewFrame = CGRect(
                origin: CGPoint(x: textOriginX, y: maxY),
                size: CGSize(
                    width: min(
                        photosWidth,
                        maxWidth - insets.right - insets.left - Layout.avatarSize.width - avatarToUsernameSpacing
                    ),
                    height: Layout.photoSize.height
                )
            )
            maxY = photosScrollViewFrame.maxY + photosToTextSpacing
            photosStackViewFrame = CGRect(
                origin: .zero,
                size: CGSize(width: photosWidth, height: Layout.photoSize.height)
            )
        }

        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: textOriginX, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: textOriginX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: textOriginX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
