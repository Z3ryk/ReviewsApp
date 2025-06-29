import UIKit

typealias ReviewsTotalCountCell = UITableViewCell

struct ReviewsTotalCountCellConfig {

    /// Идентификатор для переиспользования ячейки
    static let reuseId = String(describing: ReviewsTotalCountCellConfig.self)

    /// Текст про количество отзывов всего
    let text: String

}

// MARK: - TableCellConfig

extension ReviewsTotalCountCellConfig: TableCellConfig {

    func update(cell: UITableViewCell) {
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = text
        contentConfiguration.textProperties.alignment = .center
        contentConfiguration.textProperties.font = .reviewCount
        contentConfiguration.textProperties.color = .reviewCount
        cell.contentConfiguration = contentConfiguration
    }

    func height(with size: CGSize) -> CGFloat {
        UITableView.automaticDimension
    }

}
