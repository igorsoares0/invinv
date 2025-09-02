import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/client_service.dart';
import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final ClientService _clientService;

  ClientBloc(this._clientService) : super(ClientInitial()) {
    on<LoadClients>(_onLoadClients);
    on<SearchClients>(_onSearchClients);
    on<AddClient>(_onAddClient);
    on<UpdateClient>(_onUpdateClient);
    on<DeleteClient>(_onDeleteClient);
    on<LoadClientDetails>(_onLoadClientDetails);
  }

  Future<void> _onLoadClients(LoadClients event, Emitter<ClientState> emit) async {
    try {
      emit(ClientLoading());
      final clients = await _clientService.getAllClients();
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientError('Failed to load clients: ${e.toString()}'));
    }
  }

  Future<void> _onSearchClients(SearchClients event, Emitter<ClientState> emit) async {
    try {
      emit(ClientLoading());
      final clients = event.query.isEmpty 
          ? await _clientService.getAllClients()
          : await _clientService.searchClients(event.query);
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientError('Failed to search clients: ${e.toString()}'));
    }
  }

  Future<void> _onAddClient(AddClient event, Emitter<ClientState> emit) async {
    try {
      await _clientService.createClient(event.client);
      emit(const ClientOperationSuccess('Client added successfully'));
      add(LoadClients());
    } catch (e) {
      emit(ClientError('Failed to add client: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateClient(UpdateClient event, Emitter<ClientState> emit) async {
    try {
      await _clientService.updateClient(event.client);
      emit(const ClientOperationSuccess('Client updated successfully'));
      add(LoadClients());
    } catch (e) {
      emit(ClientError('Failed to update client: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteClient(DeleteClient event, Emitter<ClientState> emit) async {
    try {
      await _clientService.deleteClient(event.clientId);
      emit(const ClientOperationSuccess('Client deleted successfully'));
      add(LoadClients());
    } catch (e) {
      emit(ClientError('Failed to delete client: ${e.toString()}'));
    }
  }

  Future<void> _onLoadClientDetails(LoadClientDetails event, Emitter<ClientState> emit) async {
    try {
      emit(ClientLoading());
      
      final client = await _clientService.getClientById(event.clientId);
      if (client == null) {
        emit(const ClientError('Client not found'));
        return;
      }

      final invoiceHistory = await _clientService.getClientInvoiceHistory(event.clientId);
      final stats = await _clientService.getClientStats(event.clientId);

      emit(ClientDetailsLoaded(
        client: client,
        invoiceHistory: invoiceHistory,
        stats: stats,
      ));
    } catch (e) {
      emit(ClientError('Failed to load client details: ${e.toString()}'));
    }
  }
}