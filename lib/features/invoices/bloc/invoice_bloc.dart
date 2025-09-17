import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/services/invoice_service.dart';
import '../../../shared/services/client_service.dart';
import '../../../shared/models/models.dart';

// Events
abstract class InvoiceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {}
class LoadInvoiceDetails extends InvoiceEvent {
  final int invoiceId;
  LoadInvoiceDetails(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}
class CreateInvoice extends InvoiceEvent {
  final Invoice invoice;
  final List<InvoiceItem> items;
  CreateInvoice(this.invoice, this.items);
  @override
  List<Object?> get props => [invoice, items];
}
class UpdateInvoice extends InvoiceEvent {
  final Invoice invoice;
  final List<InvoiceItem> items;
  UpdateInvoice(this.invoice, this.items);
  @override
  List<Object?> get props => [invoice, items];
}
class UpdateInvoiceStatus extends InvoiceEvent {
  final int invoiceId;
  final InvoiceStatus status;
  UpdateInvoiceStatus(this.invoiceId, this.status);
  @override
  List<Object?> get props => [invoiceId, status];
}
class DeleteInvoice extends InvoiceEvent {
  final int invoiceId;
  DeleteInvoice(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}
class ConvertEstimateToInvoice extends InvoiceEvent {
  final int estimateId;
  ConvertEstimateToInvoice(this.estimateId);
  @override
  List<Object?> get props => [estimateId];
}

// States
abstract class InvoiceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}
class InvoiceLoading extends InvoiceState {}
class InvoiceLoaded extends InvoiceState {
  final List<Invoice> invoices;
  InvoiceLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}
class InvoiceDetailsLoaded extends InvoiceState {
  final Map<String, dynamic> invoiceDetails;
  InvoiceDetailsLoaded(this.invoiceDetails);
  @override
  List<Object?> get props => [invoiceDetails];
}
class InvoiceError extends InvoiceState {
  final String message;
  InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}
class InvoiceOperationSuccess extends InvoiceState {
  final String message;
  InvoiceOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceService _invoiceService;

  InvoiceBloc(this._invoiceService) : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<LoadInvoiceDetails>(_onLoadInvoiceDetails);
    on<CreateInvoice>(_onCreateInvoice);
    on<UpdateInvoice>(_onUpdateInvoice);
    on<UpdateInvoiceStatus>(_onUpdateInvoiceStatus);
    on<DeleteInvoice>(_onDeleteInvoice);
    on<ConvertEstimateToInvoice>(_onConvertEstimateToInvoice);
  }

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<InvoiceState> emit) async {
    try {
      emit(InvoiceLoading());
      final invoices = await _invoiceService.getAllInvoices();
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError('Failed to load invoices: ${e.toString()}'));
    }
  }

  Future<void> _onLoadInvoiceDetails(LoadInvoiceDetails event, Emitter<InvoiceState> emit) async {
    try {
      emit(InvoiceLoading());
      final details = await _invoiceService.getInvoiceWithDetails(event.invoiceId);
      if (details == null) {
        emit(InvoiceError('Invoice not found'));
        return;
      }
      emit(InvoiceDetailsLoaded(details));
    } catch (e) {
      emit(InvoiceError('Failed to load invoice details: ${e.toString()}'));
    }
  }

  Future<void> _onCreateInvoice(CreateInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await _invoiceService.createInvoice(event.invoice, event.items);
      emit(InvoiceOperationSuccess('Invoice created successfully'));
      add(LoadInvoices());
    } catch (e) {
      emit(InvoiceError('Failed to create invoice: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateInvoice(UpdateInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await _invoiceService.updateInvoice(event.invoice, event.items);
      emit(InvoiceOperationSuccess('Invoice updated successfully'));
      add(LoadInvoices());
    } catch (e) {
      emit(InvoiceError('Failed to update invoice: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateInvoiceStatus(UpdateInvoiceStatus event, Emitter<InvoiceState> emit) async {
    try {
      await _invoiceService.updateInvoiceStatus(event.invoiceId, event.status);
      emit(InvoiceOperationSuccess('Invoice status updated'));
      add(LoadInvoices());
    } catch (e) {
      emit(InvoiceError('Failed to update invoice status: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteInvoice(DeleteInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await _invoiceService.deleteInvoice(event.invoiceId);
      emit(InvoiceOperationSuccess('Invoice deleted successfully'));
      add(LoadInvoices());
    } catch (e) {
      emit(InvoiceError('Failed to delete invoice: ${e.toString()}'));
    }
  }

  Future<void> _onConvertEstimateToInvoice(ConvertEstimateToInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await _invoiceService.convertEstimateToInvoice(event.estimateId);
      emit(InvoiceOperationSuccess('Estimate converted to invoice'));
      add(LoadInvoices());
    } catch (e) {
      emit(InvoiceError('Failed to convert estimate: ${e.toString()}'));
    }
  }
}