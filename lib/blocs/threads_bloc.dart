import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/messages_bloc.dart';
import 'package:twake/events/messages_event.dart';
import 'package:twake/models/message.dart';
import 'package:twake/repositories/collection_repository.dart';
import 'package:twake/states/messages_state.dart';

export 'package:twake/states/messages_state.dart';
export 'package:twake/events/messages_event.dart';

class ThreadsBloc extends Bloc<MessagesEvent, MessagesState> {
  final CollectionRepository<Message> repository;
  final MessagesBloc messagesBloc;
  StreamSubscription subscription;
  String _selectedThreadId;

  ThreadsBloc({this.repository, this.messagesBloc}) : super(MessagesEmpty()) {
    subscription = messagesBloc.listen((MessagesState state) {
      if (state is MessageSelected) {
        _selectedThreadId = state.threadMessage.id;
        this.add(LoadMessages(threadId: _selectedThreadId));
      }
    });
  }

  @override
  Stream<MessagesState> mapEventToState(MessagesEvent event) async* {
    if (event is LoadMessages) {
      yield MessagesLoading();
      List<List> filters = [
        ['threadId', '!=', null],
        ['threadId', '=', _selectedThreadId],
      ];
      await repository.reload(
        queryParams: _makeQueryParams(event),
        filters: filters,
      );
      if (repository.items.isEmpty)
        yield MessagesEmpty();
      else
        yield MessagesLoaded(messages: repository.items);
    } else if (event is LoadSingleMessage) {
      await repository.pullOne(
        _makeQueryParams(event),
        addToItems: event.threadId == _selectedThreadId,
      );
      yield MessagesLoaded(messages: repository.items);
    } else if (event is RemoveMessage) {
      await repository.delete(
        event.messageId,
        apiSync: !event.onNotify,
        removeFromItems: event.threadId == _selectedThreadId,
        requestBody: _makeQueryParams(event),
      );
      if (repository.items.isEmpty)
        yield MessagesEmpty();
      else
        yield MessagesLoaded(messages: repository.items);
    } else if (event is SendMessage) {
      await repository.add(_makeQueryParams(event));
      yield MessagesLoaded(messages: repository.items);
    } else if (event is ClearMessages) {
      await repository.clean();
      yield MessagesEmpty();
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }

  Map<String, dynamic> _makeQueryParams(MessagesEvent event) {
    Map<String, dynamic> map = event.toMap();
    map['channel_id'] = map['channel_id'] ?? messagesBloc.selectedChannelId;
    map['company_id'] =
        messagesBloc.channelsBloc.workspacesBloc.selectedCompanyId;
    map['workspace_id'] =
        messagesBloc.channelsBloc.workspacesBloc.repository.selected.id;
    return map;
  }
}