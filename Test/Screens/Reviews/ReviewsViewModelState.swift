/// Модель, хранящая состояние вью модели.
struct ReviewsViewModelState {

    var items = [any TableCellConfig]()
    var limit = 20
    var offset = 0
    var shouldLoad = true

}

enum ReviewsViewState {
    case loading
    case content
    case error
}
