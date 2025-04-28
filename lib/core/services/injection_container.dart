import 'package:get_it/get_it.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/datasource/local_datasource/delivery_team_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/datasource/remote_datasource/delivery_team_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/repo/delivery_team_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/assign_delivery_team_to_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/load_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/load_delivery_team_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/datasource/local_datasource/personel_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/datasource/remote_datasource/personel_remote_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/repo/personels_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/repo/personal_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/usecase/get_personels.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/usecase/load_personels_by_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/usecase/load_personels_by_trip_Id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/usecase/set_role.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/datasource/local_datasource/vehicle_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/datasource/remote_datasource/vehicle_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/repo/vehicle_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/get_vehicle.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/load_vehicle_by_delivery_team_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/load_vehicle_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/datasource/local_datasource/completed_local_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/datasource/remote_datasource/completed_customer_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/repo/completed_customer_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/repo/completed_customer_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer_by_id_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/datasource/local_datasource/customer_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/datasource/remote_datasource/customer_remote_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/repo/customer_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/repo/customer_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/calculate_customer_total_time.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/get_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/get_customersLocation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/remote_datasource/delivery_update_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/local_datasource/delivery_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/repo/delivery_update_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/check_end_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/complete_delivery_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/create_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_delivery_update.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/itialized_pending_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_queue_remarks.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/datasource/remote_data_source/invoice_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/datasource/local_datasource/invoice_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/repo/invoice_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice_per_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice_per_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/set_all_invoices_completed.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/set_invoice_unloaded.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/datasource/local_datasource/product_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/datasource/remote_datasource/product_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/repo/product_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/add_to_return_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/confirm_delivery_products.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/get_product.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/get_products_by_invoice_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_product_quantities.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_return_reason_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_status_product.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/datasource/local_datasource/return_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/datasource/remote_datasource/return_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/repo/return_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/repo/return_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_by_customerId.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/datasource/local_datasource/transaction_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/datasource/remote_datasource/transaction_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/repo/transaction_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/create_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/delete_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/generate_pdf.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_completed_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_date_range_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_id_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/update_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/datasource/local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/datasource/remote_datasource/trip_remote_datasurce.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/repo/trip_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/accept_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/calculate_total_distance.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/check_end_trip_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/end_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trip_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trips_by_date_range.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/scan_qr_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_trip_by_details.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/update_trip_location.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/local_datasource/trip_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/repo/trip_update_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/create_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/get_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/datasources/local_datasource/undeliverable_customer_local_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/datasources/remote_datasource/undeliverable_customer_remote_datasrc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/repo/undeliverable_customer_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/create_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/delete_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/get_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/get_undeliverable_customer_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/save_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/set_undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/update_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/local_datasource/update_timeline_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/remote_datasource/update_timeline_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/repo/update_timeline_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/repo/update_timeline_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/load_update_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/set_update_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/presentation/bloc/update_timeline_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/local_datasource/checklist_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/remote_datasource/checklist_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/repo/checklist_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/check_Item.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_Checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_checklist_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/repo/end_trip_checklist_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/check_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/generate_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/load_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/local_datasource/end_trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/repo/end_trip_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/end_otp_verify.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/get_end_trip_generated.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';


import 'package:x_pro_delivery_app/core/common/app/features/otp/data/datasource/local_datasource/otp_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/datasource/remote_data_source/otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/repo/otp_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/get_generated_otp.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/load_otp_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/load_otp_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/verify_in_transit.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/veryfy_in_end_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/delivery_timeline_status_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';
import 'package:x_pro_delivery_app/src/auth/data/datasources/local_datasource/auth_local_data_source.dart';
import 'package:x_pro_delivery_app/src/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/src/auth/data/repo/auth_repo_impl.dart';
import 'package:x_pro_delivery_app/src/auth/domain/repo/auth_repo.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_by_id.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_trip.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/load_user.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/refresh_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sign_in.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_trip_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_user_data.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/data/repo/onboarding_repo_impl.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/repo/onboarding_repo.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/cache_firstimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/check_if_user_firsttimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_bloc.dart';

import '../../src/on_boarding/data/local_datasource/onboarding_local_datasource.dart';

final sl = GetIt.instance;
final pb = PocketBase('http://192.168.1.118:8090');

Future<void> init() async {
  final objectBoxStore = await ObjectBoxStore.create();
  sl.registerLazySingleton<ObjectBoxStore>(() => objectBoxStore);

  // Add SyncService registration
  sl.registerLazySingleton(() => SyncService());

  await initAuth();
  await initOnboarding();
  await initGetCustomer();
  await initChecklist();
  await initGetVehicle();
  await initPersonel(); // Add this
  await initDeliveryTeam(); // Add this
  await initTrip();
  await initInvoice();
  await initProduct();
  await initDeliveryUpdate();
  await initUpdateTimeline();
  await initOtp();
  await initEndTripOtp();
  await initTransaction();
  await initReturnProducts();
  await initCompletedCustomers();
  await initUndeliverableCustomer();
  await initEndTripChecklist();
  await initTripUpdate();
  sl.registerLazySingleton(() => ConnectivityProvider());
}



Future<void> initOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerFactory(
    () => OnboardingBloc(cacheFirstTimer: sl(), checkIfUserIsFirstimer: sl()),
  );

  sl.registerLazySingleton(
    () => CacheFirstTimer(sl()),
  );

  sl.registerLazySingleton(
    () => CheckIfUserIsFirstimer(sl()),
  );

  sl.registerLazySingleton<OnboardingRepo>(
    () => OnboardingRepoImpl(sl()),
  );

  sl.registerLazySingleton<OnboardingLocalDatasource>(
    () => OnboardingLocalDatasourceImpl(sl()),
  );

  sl.registerLazySingleton(
    () => prefs,
  );
}

Future<void> initAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => AuthBloc(
        signIn: sl(),
        refreshUserData: sl(),
        getUserById: sl(),
        loadUser: sl(),
        getUserTrip: sl(),
        syncUserData: sl(),
        syncUserTripData: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SyncUserData(sl()));
  sl.registerLazySingleton(() => SyncUserTripData(sl()));

  sl.registerLazySingleton(() => GetUserTrip(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));
  sl.registerLazySingleton(() => LoadUser(sl()));
  sl.registerLazySingleton(() => RefreshUserData(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl(), sl()));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSrc>(
    () => AuthRemoteDataSrcImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSrc>(
    () => AuthLocalDataSrcImpl(objectBoxStore.store, prefs),
  );

  // External
  sl.registerLazySingleton(() => pb);
  sl.registerLazySingleton(() => UserProvider());
}


Future<void> initGetCustomer() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => CustomerBloc(
        getCustomer: sl(),
        deliveryUpdateBloc: sl(),
        invoiceBloc: sl(),
        getCustomersLocation: sl(),
        calculateCustomerTotalTime: sl()),
  );

  sl.registerLazySingleton(
    () => GetCustomer(sl()),
  );

  sl.registerLazySingleton(
    () => CalculateCustomerTotalTime(sl()),
  );
  sl.registerLazySingleton(
    () => GetCustomersLocation(sl()),
  );

  sl.registerLazySingleton<CustomerRepo>(
    () => CustomerRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(
      pocketBaseClient: sl(),
    ),
  );

  sl.registerLazySingleton<CustomerLocalDatasource>(
    () =>
        CustomerLocalDatasourceImpl(objectBoxStore.store.box<CustomerModel>()),
  );
}

Future<void> initChecklist() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => ChecklistBloc(
        loadChecklist: sl(), checkItem: sl(), loadChecklistByTripId: sl()),
  );

  sl.registerLazySingleton(
    () => LoadChecklist(sl()),
  );

  sl.registerLazySingleton(
    () => LoadChecklistByTripId(sl()),
  );

  sl.registerLazySingleton(
    () => CheckItem(sl()),
  );

  sl.registerLazySingleton<ChecklistRepo>(
    () => ChecklistRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<ChecklistDatasource>(
    () => ChecklistDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<ChecklistLocalDatasource>(
    () => ChecklistLocalDatasourceImpl(
        objectBoxStore.store.box<ChecklistModel>()),
  );
}

Future<void> initGetVehicle() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => VehicleBloc(
        getVehicle: sl(),
        loadVehicleByTripId: sl(),
        loadVehicleByDeliveryTeam: sl()),
  );

  sl.registerLazySingleton(
    () => GetVehicle(sl()),
  );

  sl.registerLazySingleton(
    () => LoadVehicleByDeliveryTeam(sl()),
  );

  sl.registerLazySingleton(
    () => LoadVehicleByTripId(sl()),
  );

  sl.registerLazySingleton<VehicleRepo>(
    () => VehicleRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<VehicleRemoteDatasource>(
    () => VehicleRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<VehicleLocalDatasource>(
    () => VehicleLocalDatasourceImpl(objectBoxStore.store.box<VehicleModel>()),
  );
}

Future<void> initPersonel() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => PersonelBloc(
      getPersonels: sl(),
      setRole: sl(),
      loadPersonelsByTripId: sl(),
      loadPersonelsByDeliveryTeam: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => GetPersonels(sl()),
  );

  sl.registerLazySingleton(
    () => SetRole(sl()),
  );

  sl.registerLazySingleton(
    () => LoadPersonelsByDeliveryTeam(sl()),
  );

  sl.registerLazySingleton(
    () => LoadPersonelsByTripId(sl()),
  );

  sl.registerLazySingleton<PersonelRepo>(
    () => PersonelsRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<PersonelRemoteDataSource>(
    () => PersonelRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<PersonelLocalDatasource>(
    () =>
        PersonelLocalDatasourceImpl(objectBoxStore.store.box<PersonelModel>()),
  );
}

Future<void> initDeliveryTeam() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => DeliveryTeamBloc(
        loadDeliveryTeam: sl(),
        tripBloc: sl(),
        personelBloc: sl(),
        vehicleBloc: sl(),
        loadDeliveryTeamById: sl(),
        checklistBloc: sl(),
        assignDeliveryTeamToTrip: sl()),
  );

  sl.registerLazySingleton(
    () => LoadDeliveryTeam(sl()),
  );

  sl.registerLazySingleton(
    () => LoadDeliveryTeamById(sl()),
  );

  sl.registerLazySingleton(
    () => AssignDeliveryTeamToTrip(sl()),
  );

  sl.registerLazySingleton<DeliveryTeamRepo>(
    () => DeliveryTeamRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<DeliveryTeamDatasource>(
    () => DeliveryTeamDatasourceImpl(
        pocketBaseClient: sl(), deliveryTeamBox: sl()),
  );

  // Register the Box<DeliveryTeamModel>
  sl.registerLazySingleton<Box<DeliveryTeamModel>>(
    () => objectBoxStore.store.box<DeliveryTeamModel>(),
  );

  sl.registerLazySingleton<DeliveryTeamLocalDatasource>(
    () => DeliveryTeamLocalDatasourceImpl(
      objectBoxStore.store.box<DeliveryTeamModel>(),
    ),
  );
}

Future<void> initTrip() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => TripBloc(
        getTrip: sl(),
        searchTrip: sl(),
        customerBloc: sl(),
        updateTimelineBloc: sl(),
        acceptTrip: sl(),
        checkEndTripStatus: sl(),
        searchTrips: sl(),
        getTripsByDateRange: sl(),
        calculateTotalTripDistance: sl(),
        scanQRUsecase: sl(),
        getTripById: sl(),
        endTrip: sl(),
        updateTripLocation: sl()),
  );

  sl.registerLazySingleton(
    () => GetTrip(sl()),
  );

  sl.registerLazySingleton(
    () => GetTripById(sl()),
  );

  sl.registerLazySingleton(
    () => SearchTrip(sl()),
  );

  sl.registerLazySingleton(
    () => UpdateTripLocation(sl()),
  );

  sl.registerLazySingleton(
    () => AcceptTrip(sl()),
  );

  sl.registerLazySingleton(
    () => CheckEndTripStatus(sl()),
  );

  sl.registerLazySingleton(
    () => SearchTrips(sl()),
  );

  sl.registerLazySingleton(
    () => GetTripsByDateRange(sl()),
  );

  sl.registerLazySingleton(
    () => CalculateTotalTripDistance(sl()),
  );

  sl.registerLazySingleton(
    () => ScanQRUsecase(sl()),
  );

  sl.registerLazySingleton(
    () => EndTrip(sl()),
  );

  sl.registerLazySingleton<TripRepo>(
    () => TripRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<TripRemoteDatasurce>(
    () => TripRemoteDatasurceImpl(
        pocketBaseClient: sl(), tripLocalDatasource: sl()),
  );

  sl.registerLazySingleton<TripLocalDatasource>(
    () => TripLocalDatasourceImpl(
      objectBoxStore.store,
      objectBoxStore.store.box<TripModel>(),
      sl(), // Provides the PocketBase client
    ),
  );
}

Future<void> initInvoice() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => InvoiceBloc(
        productsBloc: sl(),
        getInvoices: sl(),
        getInvoicesByTrip: sl(),
        getInvoicesByCustomer: sl(), setAllInvoicesCompleted: sl(), setInvoiceUnloaded: sl()),
  );

  sl.registerLazySingleton(
    () => GetInvoice(sl()),
  );

  sl.registerLazySingleton(
    () => SetInvoiceUnloaded(sl()),
  );


  sl.registerLazySingleton(
    () => SetAllInvoicesCompleted(sl()),
  );


  sl.registerLazySingleton(
    () => GetInvoicesByCustomer(sl()),
  );

  sl.registerLazySingleton(
    () => GetInvoicesByTrip(sl()),
  );

  sl.registerLazySingleton<InvoiceRepo>(
    () => InvoiceRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<InvoiceRemoteDatasource>(
    () => InvoiceRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<InvoiceLocalDatasource>(
    () => InvoiceLocalDatasourceImpl(objectBoxStore.store.box<InvoiceModel>()),
  );
}

Future<void> initProduct() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => ProductsBloc(
        getProduct: sl(),
        updateStatusProduct: sl(),
        confirmDeliveryProducts: sl(),
        addToReturn: sl(),
        updateReturnReason: sl(),
        updateProductQuantities: sl(),
        getProductsByInvoice: sl()),
  );

  sl.registerLazySingleton(
    () => GetProductsByInvoice(sl()),
  );
  sl.registerLazySingleton(() => GetProduct(sl()));
  sl.registerLazySingleton(() => UpdateStatusProduct(sl()));
  sl.registerLazySingleton(() => ConfirmDeliveryProducts(sl()));
  sl.registerLazySingleton(() => AddToReturnUsecase(sl()));
  sl.registerLazySingleton(() => UpdateReturnReasonUsecase(sl()));
  sl.registerLazySingleton(() => UpdateProductQuantities(sl()));
  sl.registerLazySingleton<ProductRepo>(
    () => ProductRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<ProductRemoteDatasource>(
    () => ProductRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<ProductLocalDatasource>(
    () => ProductLocalDatasourceImpl(objectBoxStore.store.box<ProductModel>()),
  );
}

Future<void> initDeliveryUpdate() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => DeliveryUpdateBloc(
        getDeliveryStatusChoices: sl(),
        updateDeliveryStatus: sl(),
        completeDelivery: sl(),
        checkEndDeliverStatus: sl(),
        initializePendingStatus: sl(),
        createDeliveryStatus: sl(),
        updateQueueRemarks: sl()),
  );
  sl.registerLazySingleton(() => CompleteDelivery(sl()));
  sl.registerLazySingleton(() => GetDeliveryStatusChoices(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => CheckEndDeliverStatus(sl()));
  sl.registerLazySingleton(() => InitializePendingStatus(sl()));
  sl.registerLazySingleton(() => CreateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => UpdateQueueRemarks(sl()));
  sl.registerLazySingleton<DeliveryUpdateRepo>(
    () => DeliveryUpdateRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<DeliveryUpdateDatasource>(
    () => DeliveryUpdateDatasourceImpl(pocketBaseClient: sl()),
  );
  sl.registerLazySingleton<DeliveryUpdateLocalDatasource>(
    () => DeliveryUpdateLocalDatasourceImpl(
      objectBoxStore.store.box<DeliveryUpdateModel>(),
      objectBoxStore.store.box<CustomerModel>(),
    ),
  );

  sl.registerLazySingleton(
    () => DeliveryStatusProvider(deliveryUpdateBloc: sl()),
  );
}

Future<void> initUpdateTimeline() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => UpdateTimelineBloc(loadUpdateTimeline: sl(), setDeliveryUpdate: sl()),
  );

  sl.registerLazySingleton(() => LoadUpdateTimeline(sl()));
  sl.registerLazySingleton(() => SetUpdateTimeline(sl()));

  sl.registerLazySingleton<UpdateTimelineRepo>(
    () => UpdateTimelineRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<UpdateTimelineDatasource>(
    () => UpdateTimelineDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<UpdateTimelineLocalDatasource>(
    () => UpdateTimelineLocalDatasourceImpl(
        objectBoxStore.store.box<UpdateTimelineModel>()),
  );
}

Future<void> initOtp() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(() => OtpBloc(
        getGeneratedOtp: sl(),
        verifyEndDelivery: sl(),
        verifyInTransit: sl(),
        loadOtpByTripId: sl(),
        loadOtpById: sl(),
      ));
  sl.registerLazySingleton(() => LoadOtpById(sl()));
  sl.registerLazySingleton(() => LoadOtpByTripId(sl()));
  sl.registerLazySingleton(() => GetGeneratedOtp(sl()));
  sl.registerLazySingleton(() => VerifyInTransit(sl()));
  sl.registerLazySingleton(() => VerifyInEndDelivery(sl()));
  sl.registerLazySingleton<OtpRepo>(
    () => OtpRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<OtpRemoteDataSource>(
    () => OtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<OtpLocalDatasource>(
    () => OtpLocalDatasourceImpl(objectBoxStore.store.box<OtpModel>()),
  );
}

Future<void> initEndTripOtp() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // Bloc
  sl.registerFactory(() => EndTripOtpBloc(
        verifyEndTripOtp: sl(),
        getGeneratedEndTripOtp: sl(),
        loadEndTripOtpById: sl(),
        loadEndTripOtpByTripId: sl(),
      ));

  // Usecases
  sl.registerLazySingleton(() => EndOTPVerify(sl()));
  sl.registerLazySingleton(() => GetEndTripGeneratedOtp(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpByTripId(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpById(sl()));

  // Repository
  sl.registerLazySingleton<EndTripOtpRepo>(
    () => EndTripOtpRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<EndTripOtpRemoteDataSource>(
    () => EndTripOtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<EndTripOtpLocalDatasource>(
    () => EndTripOtpLocalDatasourceImpl(
      objectBoxStore.store.box<EndTripOtpModel>(),
    ),
  );
}

Future<void> initTransaction() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => TransactionBloc(
        createTransaction: sl(),
        deleteTransaction: sl(),
        getTransactionById: sl(),
        getTransactionsByDateRange: sl(),
        getTransactions: sl(),
        updateTransaction: sl(),
        generateTransactionPdf: sl(),
        getTransactionsByCompletedCustomer: sl()),
  );

  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByCompletedCustomer(sl()));
  sl.registerLazySingleton(() => GetLocalTransactionByIdEvent(sl()));
  sl.registerLazySingleton(() => GetLocalTransactionsEvent(sl()));
  sl.registerLazySingleton(() => GenerateTransactionPdf(sl()));

  sl.registerLazySingleton<TransactionRepo>(
    () => TransactionRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<TransactionLocalDatasource>(
    () => TransactionLocalDatasourceImpl(
        objectBoxStore.store.box<TransactionModel>(),
        objectBoxStore.store.box<CustomerModel>(),
        objectBoxStore.store),
  );
}

Future<void> initReturnProducts() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => ReturnBloc(getReturns: sl(), getReturnByCustomerId: sl()),
  );

  sl.registerLazySingleton(
    () => GetReturnUsecase(sl()),
  );

  sl.registerLazySingleton(
    () => GetReturnByCustomerId(sl()),
  );

  sl.registerLazySingleton<ReturnRepo>(() => ReturnRepoImpl(sl(), sl()));

  sl.registerLazySingleton<ReturnRemoteDatasource>(
    () => ReturnRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<ReturnLocalDatasource>(
    () => ReturnLocalDatasourceImpl(objectBoxStore.store.box<ReturnModel>()),
  );
}

Future<void> initCompletedCustomers() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => CompletedCustomerBloc(
        getCompletedCustomers: sl(),
        getCompletedCustomerById: sl(),
        invoiceBloc: sl()),
  );

  sl.registerLazySingleton(
    () => GetCompletedCustomer(sl()),
  );

  sl.registerLazySingleton(
    () => GetCompletedCustomerById(sl()),
  );

  sl.registerCachedFactory<CompletedCustomerRepo>(
    () => CompletedCustomerRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<CompletedCustomerRemoteDatasource>(
    () => CompletedCustomerRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<CompletedCustomerLocalDatasource>(
    () => CompletedCustomerLocalDatasourceImpl(
        objectBoxStore.store.box<CompletedCustomerModel>()),
  );
}



Future<void> initUndeliverableCustomer() async {
  final objectBoxStore = await ObjectBoxStore.create();
  // Bloc
  sl.registerFactory(() => UndeliverableCustomerBloc(
        getUndeliverableCustomers: sl(),
        createUndeliverableCustomer: sl(),
        saveUndeliverableCustomer: sl(),
        updateUndeliverableCustomer: sl(),
        deleteUndeliverableCustomer: sl(),
        setUndeliverableReason: sl(),
        getUndeliverableCustomerById: sl(),
      ));

  // Usecases
  sl.registerLazySingleton(() => GetUndeliverableCustomers(sl()));
  sl.registerLazySingleton(() => CreateUndeliverableCustomer(sl()));
  sl.registerLazySingleton(() => SaveUndeliverableCustomer(sl()));
  sl.registerLazySingleton(() => UpdateUndeliverableCustomer(sl()));
  sl.registerLazySingleton(() => DeleteUndeliverableCustomer(sl()));
  sl.registerLazySingleton(() => SetUndeliverableReason(sl()));
  sl.registerLazySingleton(() => GetUndeliverableCustomerById(sl()));

  // Repository
  sl.registerLazySingleton<UndeliverableRepo>(
    () => UndeliverableCustomerRepoImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<UndeliverableCustomerRemoteDataSource>(
    () => UndeliverableCustomerRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
  sl.registerLazySingleton<UndeliverableCustomerLocalDataSource>(
    () => UndeliverableCustomerLocalDataSourceImpl(
      objectBoxStore.store.box<UndeliverableCustomerModel>(),
    ),
  );
}

Future<void> initEndTripChecklist() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // Bloc
  sl.registerFactory(
    () => EndTripChecklistBloc(
      generateEndTripChecklist: sl(),
      checkEndTripChecklist: sl(),
      loadEndTripChecklist: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GenerateEndTripChecklist(sl()));
  sl.registerLazySingleton(() => CheckEndTripChecklist(sl()));
  sl.registerLazySingleton(() => LoadEndTripChecklist(sl()));

  // Repository
  sl.registerLazySingleton<EndTripChecklistRepo>(
    () => EndTripChecklistRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<EndTripChecklistRemoteDataSource>(
    () => EndTripChecklistRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<EndTripChecklistLocalDataSource>(
    () => EndTripChecklistLocalDataSourceImpl(
      objectBoxStore.store.box<EndTripChecklistModel>(),
    ),
  );
}

Future<void> initTripUpdate() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => TripUpdatesBloc(getTripUpdates: sl(), createTripUpdate: sl()),
  );

  sl.registerLazySingleton(() => GetTripUpdates(sl()));
  sl.registerLazySingleton(() => CreateTripUpdate(sl()));

  sl.registerLazySingleton<TripUpdateRepo>(
    () => TripUpdateRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<TripUpdateRemoteDatasource>(
    () => TripUpdateRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<TripUpdateLocalDatasource>(() =>
      TripUpdateLocalDatasourceImpl(
          objectBoxStore.store.box<TripUpdateModel>()));
}
