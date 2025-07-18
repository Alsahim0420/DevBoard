import 'package:flutter_bloc/flutter_bloc.dart';

// Eventos
abstract class ModalEvent {}

class ShowCreateBoardModal extends ModalEvent {}

class HideCreateBoardModal extends ModalEvent {}

// Estados
abstract class ModalState {
  final bool showCreateBoardModal;

  const ModalState({required this.showCreateBoardModal});
}

class ModalInitial extends ModalState {
  const ModalInitial() : super(showCreateBoardModal: false);
}

class ModalUpdated extends ModalState {
  const ModalUpdated({required super.showCreateBoardModal});
}

// Bloc
class ModalBloc extends Bloc<ModalEvent, ModalState> {
  ModalBloc() : super(const ModalInitial()) {
    on<ShowCreateBoardModal>(_onShowCreateBoardModal);
    on<HideCreateBoardModal>(_onHideCreateBoardModal);
  }

  void _onShowCreateBoardModal(
      ShowCreateBoardModal event, Emitter<ModalState> emit) {
    emit(const ModalUpdated(showCreateBoardModal: true));
  }

  void _onHideCreateBoardModal(
      HideCreateBoardModal event, Emitter<ModalState> emit) {
    emit(const ModalUpdated(showCreateBoardModal: false));
  }
}
