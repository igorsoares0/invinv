import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/services/product_service.dart';
import '../../../shared/models/models.dart';

abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}
class SearchProducts extends ProductEvent {
  final String query;
  SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}
class AddProduct extends ProductEvent {
  final Product product;
  AddProduct(this.product);
  @override
  List<Object?> get props => [product];
}
class UpdateProduct extends ProductEvent {
  final Product product;
  UpdateProduct(this.product);
  @override
  List<Object?> get props => [product];
}
class DeleteProduct extends ProductEvent {
  final int productId;
  DeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}

abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
  @override
  List<Object?> get props => [message];
}
class ProductOperationSuccess extends ProductState {
  final String message;
  ProductOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _productService;

  ProductBloc(this._productService) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    try {
      emit(ProductLoading());
      final products = await _productService.getAllProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError('Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProducts(SearchProducts event, Emitter<ProductState> emit) async {
    try {
      emit(ProductLoading());
      final products = event.query.isEmpty 
          ? await _productService.getAllProducts()
          : await _productService.searchProducts(event.query);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError('Failed to search products: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    try {
      await _productService.createProduct(event.product);
      emit(ProductOperationSuccess('Product added successfully'));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    try {
      await _productService.updateProduct(event.product);
      emit(ProductOperationSuccess('Product updated successfully'));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    try {
      await _productService.deleteProduct(event.productId);
      emit(ProductOperationSuccess('Product deleted successfully'));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError('Failed to delete product: ${e.toString()}'));
    }
  }
}