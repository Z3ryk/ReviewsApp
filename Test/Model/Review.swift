import Foundation

/// Модель отзыва.
struct Review: Decodable {
    /// Имя пользователя
    let firstName: String
    /// Фамилия пользователя
    let lastName: String
    /// Ссылка на аватар пользователя
    let avatarUrl: URL?
    /// Текст отзыва
    let text: String
    /// Время создания отзыва
    let created: String
    ///  Рейтинг отзыва
    let rating: Int
}
