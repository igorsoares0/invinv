import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

abstract class ClientState extends Equatable {
  const ClientState();

  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientLoaded extends ClientState {
  final List<Client> clients;

  const ClientLoaded(this.clients);

  @override
  List<Object?> get props => [clients];
}

class ClientDetailsLoaded extends ClientState {
  final Client client;
  final List<Map<String, dynamic>> invoiceHistory;
  final Map<String, dynamic> stats;

  const ClientDetailsLoaded({
    required this.client,
    required this.invoiceHistory,
    required this.stats,
  });

  @override
  List<Object?> get props => [client, invoiceHistory, stats];
}

class ClientError extends ClientState {
  final String message;

  const ClientError(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientOperationSuccess extends ClientState {
  final String message;

  const ClientOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}