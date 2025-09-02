import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();

  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientEvent {}

class SearchClients extends ClientEvent {
  final String query;

  const SearchClients(this.query);

  @override
  List<Object?> get props => [query];
}

class AddClient extends ClientEvent {
  final Client client;

  const AddClient(this.client);

  @override
  List<Object?> get props => [client];
}

class UpdateClient extends ClientEvent {
  final Client client;

  const UpdateClient(this.client);

  @override
  List<Object?> get props => [client];
}

class DeleteClient extends ClientEvent {
  final int clientId;

  const DeleteClient(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class LoadClientDetails extends ClientEvent {
  final int clientId;

  const LoadClientDetails(this.clientId);

  @override
  List<Object?> get props => [clientId];
}