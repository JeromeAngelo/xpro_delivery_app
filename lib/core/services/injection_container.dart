import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/datasource/remote_datasource/delivery_team_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/repo/delivery_team_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/assign_delivery_team_to_trip.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/create_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/delete_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/load_all_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/update_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/datasource/remote_datasource/personel_remote_data_source.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/repo/personels_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/repo/personal_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/create_personels.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/delete_all_personels.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/delete_personels.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/get_personels.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/load_personels_by_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/load_personels_by_trip_Id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/set_role.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/usecase/update_personels.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/data/datasource/remote_datasource/vehicle_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/data/repo/vehicle_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/create_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/delete_all_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/delete_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/get_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/load_vehicle_by_delivery_team_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/load_vehicle_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/domain/usecase/update_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/resassign_trip_for_cancelled_invoice.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/remote_datasource/delivery_update_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/data/repo/delivery_update_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/check_end_delivery_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/create_delivery_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/create_delivery_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/delete_all_delivery_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/delete_delivery_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_all_delivery_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_delivery_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/itialized_pending_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_delivery_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_delivery_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_queue_remarks.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/data/datasource/remote_datasource/return_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/data/repo/return_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/repo/return_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/create_returns.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/delete_all_return.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/delete_return.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_all_returns.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_by_customerId.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_usecase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/update_returns.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/datasource/remote_datasource/trip_remote_datasurce.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/repo/trip_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/create_tripticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/delete_all_tripticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/delete_trip_ticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_all_tripticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_tripticket_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_tripticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/update_tripticket.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/data/datasources/remote_datasource/trip_coordinates_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/data/repo/trip_coordinates_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/domain/repo/trip_coordinates_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/domain/usecase/get_trip_coordinates_by_trip_id_usecase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/presentation/bloc/trip_coordinates_update_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/data/repo/trip_update_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/create_trip_updates.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/delete_all_trip_updates.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/delete_trip_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/get_all_trip_updates.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/get_trip_updates.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/update_trip_update.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/datasource/remote_datasource/checklist_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/repo/checklist_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/repo/checklist_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/check_Item.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/create_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/delete_all_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/delete_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/get_all_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/load_checklist_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/usecase/update_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_data_src.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/data/repo/end_trip_checklist_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/check_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/create_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/delete_all_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/delete_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/generate_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/get_all_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/load_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/domain/usecase/update_end_trip_checklist.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/data/repo/end_trip_otp_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/create_end_trip_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/delete_all_end_trip_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/delete_end_trip_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/end_otp_verify.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/get_all_end_trip_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/get_end_trip_generated.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/usecases/update_end_trip_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/repo/auth_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/repo/auth_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/create_users.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/delete_all_users.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/delete_users.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/get_all_users.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/get_user_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/sign_in.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/sign_out.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/usecases/update_users.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/data/repo/collection_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/usecases/get_all_collections.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/datasources/remote_datasource/customer_data_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/repo/customer_data_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/repo/customer_data_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/add_customer_to_delivery.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/create_customer_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/delete_all_customer_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/delete_customer_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_all_customer_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_customer_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_customer_data_by_delivery_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/update_customer_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/repo/delivery_data_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/delete_delivery_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/create_delivery_receipt.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/delete_delivery_receipt.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/generate_pdf.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/get_delivery_receipt_by_delivery_data_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/get_delivery_receipt_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/datasource/remote_datasource/delivery_vehicle_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/repo/delivery_vehicle_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/repo/delivery_vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_all_delivery_vehicle.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_delivery_vehicle_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_delivery_vehicle_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/datasources/remote_datasource/invoice_data_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/repo/invoice_data_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/add_invoice_data_to_delivery.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/add_invoice_data_to_invoice_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_all_invoice_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_customer_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_delivery_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/data/datasource/remote_datasource/invoice_items_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/data/repo/invoice_items_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_all_status.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_invoice_item_by_invoice_data_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/update_invoice_item_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/data/datasources/remote_datasource/invoice_preset_group_remote_data_src.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/data/repo/invoice_preset_group_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/repo/invoice_preset_group_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/usecases/add_all_invoices_to_delivery.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/usecases/get_all_invoice_preset_groups.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/usecases/get_all_unassigned_invoices.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/usecases/search_preset_group_by_ref_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/data/datasource/remote_data_source/otp_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/data/repo/otp_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/create_otp.dart'
    show CreateOtp;
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/delete_all_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/delete_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/get_all_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/get_generated_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/load_otp_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/load_otp_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/update_otp.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/verify_in_transit.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/usecases/veryfy_in_end_delivery.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/presentation/bloc/bloc/user_roles_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/data/datasources/remote_datasource/user_roles_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/data/repo_imple/user_roles_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/domain/repo/user_role_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/domain/usecases/get_all_roles_usecase.dart';

// Personnel Trip imports
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/data/datasource/remote_datasource/personnel_trip_remote_data_src.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/data/repo/personnel_trip_repo_impl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/repo/personnel_trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_all_personnel_trips.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trip_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trips_by_personnel_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trips_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_bloc.dart';

import '../common/app/features/Delivery_Team/personels/domain/usecase/get_personel_by_id.dart' show GetPersonelById;
import '../common/app/features/Trip_Ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_datasource.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/data/repo/cancelled_invoice_repo_impl.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/create_cancelled_invoice_by_delivery_data_id.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/delete_cancelled_invoice.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/get_all_cancelled_invoice.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_trip_id.dart';
import '../common/app/features/Trip_Ticket/collection/data/datasource/remote_datasource/collection_remote_datasource.dart';
import '../common/app/features/Trip_Ticket/collection/domain/repo/collection_repo.dart';
import '../common/app/features/Trip_Ticket/collection/domain/usecases/delete_collection.dart';
import '../common/app/features/Trip_Ticket/collection/domain/usecases/filter_collection_by_date.dart';
import '../common/app/features/Trip_Ticket/collection/domain/usecases/get_collection_by_id.dart';
import '../common/app/features/Trip_Ticket/collection/domain/usecases/get_collection_by_trip_id.dart'
    show GetCollectionsByTripId;
import '../common/app/features/Trip_Ticket/customer_data/domain/usecases/get_all_unassigned_customers.dart';
import '../common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data_with_trips.dart';
import '../common/app/features/Trip_Ticket/delivery_receipt/data/repo/delivery_receipt_repo_impl.dart';
import '../common/app/features/Trip_Ticket/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import '../common/app/features/Trip_Ticket/trip/domain/usecase/filter_trips_by_user.dart';
import '../common/app/features/Trip_Ticket/trip/domain/usecase/fiter_trips_by_data_range.dart';

final sl = GetIt.instance;
final pb = PocketBase('https://delivery-app.pockethost.io/');

Future<void> init() async {
  // await initAuth();
  await initGeneralAuth();
  await initUserRoles();
  await initVehicle();
  await initPersonels();
  await initDeliveryTeam();
  await initChecklist();
  await initEndTripChecklist();
  await initEndTripOtp();
  await initFirstOtp();
  await initReturns(); // Add this line
  await initDeliveryUpdateStatus();
  await initTripUpdate();
  await initTrip();
  await initTripCoordinatesUpdate();

  //new entities
  await initInvoiceData();
  await initCustomerData();
  await initInvoiceItems();
  await initInvoicePresetGroup();
  await initDeliveryData();
  await initDeliveryVehicleData();
  await initDeliveryCollectionsData();
  await initCancelledInvoiceData();
  await initDeliveryReceipt();
  await initPersonnelTrip();
}



Future<void> initGeneralAuth() async {
  //BLoC
  sl.registerLazySingleton(
    () => GeneralUserBloc(
      getAllUsers: sl(),
      createUser: sl(),
      updateUser: sl(),
      deleteUser: sl(),
      deleteAllUsers: sl(),
      signIn: sl(),
      signOut: sl(),
      getUserById: sl(),
    ),
  );

  //usecases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetAllUsers(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));
  sl.registerLazySingleton(() => CreateUser(sl()));
  sl.registerLazySingleton(() => UpdateUser(sl()));
  sl.registerLazySingleton(() => DeleteUser(sl()));
  sl.registerLazySingleton(() => DeleteAllUsers(sl()));

  sl.registerLazySingleton<GeneralUserRepo>(() => GeneralUserRepoImpl(sl()));
  sl.registerLazySingleton<GeneralUserRemoteDataSource>(
    () => GeneralUserRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  // External
  sl.registerLazySingleton(() => pb);
}

Future<void> initUserRoles() async {
  sl.registerLazySingleton(() => UserRolesBloc(getAllUserRoles: sl()));

  sl.registerLazySingleton(() => GetAllRolesUsecase(sl()));

  sl.registerLazySingleton<UserRoleRepo>(() => UserRolesRepoImpl(sl()));

  sl.registerLazySingleton<UserRolesRemoteDatasource>(
    () => UserRolesRemoteDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryTeam() async {
  // BLoC
  sl.registerLazySingleton(
    () => DeliveryTeamBloc(
      tripBloc: sl<TripBloc>(),
      personelBloc: sl<PersonelBloc>(),
      vehicleBloc: sl<VehicleBloc>(),
      checklistBloc: sl<ChecklistBloc>(),

      loadAllDeliveryTeam: sl(),
      assignDeliveryTeamToTrip: sl(),
      createDeliveryTeam: sl(),
      updateDeliveryTeam: sl(),
      deleteDeliveryTeam: sl(),
    ),
  );

  // Usecases

  sl.registerLazySingleton(() => LoadAllDeliveryTeam(sl()));
  sl.registerLazySingleton(() => AssignDeliveryTeamToTrip(sl()));
  sl.registerLazySingleton(() => CreateDeliveryTeam(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryTeam(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryTeam(sl()));

  // Repository
  sl.registerLazySingleton<DeliveryTeamRepo>(() => DeliveryTeamRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<DeliveryTeamDatasource>(
    () => DeliveryTeamDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initVehicle() async {
  // BLoC
  sl.registerLazySingleton(
    () => VehicleBloc(
      getVehicles: sl(),
      loadVehicleByTripId: sl(),
      loadVehicleByDeliveryTeam: sl(),
      createVehicle: sl(),
      updateVehicle: sl(),
      deleteVehicle: sl(),
      deleteAllVehicles: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetVehicle(sl()));
  sl.registerLazySingleton(() => LoadVehicleByTripId(sl()));
  sl.registerLazySingleton(() => LoadVehicleByDeliveryTeam(sl()));
  sl.registerLazySingleton(() => CreateVehicle(sl()));
  sl.registerLazySingleton(() => UpdateVehicle(sl()));
  sl.registerLazySingleton(() => DeleteVehicle(sl()));
  sl.registerLazySingleton(() => DeleteAllVehicles(sl()));

  // Repository
  sl.registerLazySingleton<VehicleRepo>(() => VehicleRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<VehicleRemoteDatasource>(
    () => VehicleRemoteDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initPersonels() async {
  // BLoC
  sl.registerLazySingleton(
    () => PersonelBloc(
      getPersonels: sl(),
      setRole: sl(),
      loadPersonelsByTripId: sl(),
      loadPersonelsByDeliveryTeam: sl(),
      createPersonel: sl(),
      updatePersonel: sl(),
      deletePersonel: sl(),
      deleteAllPersonels: sl(), getPersonelById: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetPersonels(sl()));
  sl.registerLazySingleton(() => SetRole(sl()));
  sl.registerLazySingleton(() => LoadPersonelsByTripId(sl()));
  sl.registerLazySingleton(() => LoadPersonelsByDeliveryTeam(sl()));
  sl.registerLazySingleton(() => CreatePersonel(sl()));
  sl.registerLazySingleton(() => UpdatePersonel(sl()));
  sl.registerLazySingleton(() => DeletePersonel(sl()));
  sl.registerLazySingleton(() => GetPersonelById(sl()));
  sl.registerLazySingleton(() => DeleteAllPersonels(sl()));

  // Repository
  sl.registerLazySingleton<PersonelRepo>(() => PersonelsRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<PersonelRemoteDataSource>(
    () => PersonelRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initChecklist() async {
  // BLoC
  sl.registerLazySingleton(
    () => ChecklistBloc(
      checkItem: sl(),
      loadChecklistByTripId: sl(),
      getAllChecklists: sl(),
      createChecklistItem: sl(),
      updateChecklistItem: sl(),
      deleteChecklistItem: sl(),
      deleteAllChecklistItems: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => CheckItem(sl()));
  sl.registerLazySingleton(() => LoadChecklistByTripId(sl()));
  sl.registerLazySingleton(() => GetAllChecklists(sl()));
  sl.registerLazySingleton(() => CreateChecklistItem(sl()));
  sl.registerLazySingleton(() => UpdateChecklistItem(sl()));
  sl.registerLazySingleton(() => DeleteChecklistItem(sl()));
  sl.registerLazySingleton(() => DeleteAllChecklistItems(sl()));

  // Repository
  sl.registerLazySingleton<ChecklistRepo>(() => ChecklistRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<ChecklistDatasource>(
    () => ChecklistDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initFirstOtp() async {
  // BLoC
  sl.registerLazySingleton(
    () => OtpBloc(
      loadOtpByTripId: sl(),
      verifyInTransit: sl(),
      verifyEndDelivery: sl(),
      getGeneratedOtp: sl(),
      loadOtpById: sl(),
      getAllOtps: sl(),
      createOtp: sl(),
      updateOtp: sl(),
      deleteOtp: sl(),
      deleteAllOtps: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => LoadOtpByTripId(sl()));
  sl.registerLazySingleton(() => VerifyInTransit(sl()));
  sl.registerLazySingleton(() => VerifyInEndDelivery(sl()));
  sl.registerLazySingleton(() => GetGeneratedOtp(sl()));
  sl.registerLazySingleton(() => LoadOtpById(sl()));
  sl.registerLazySingleton(() => GetAllOtps(sl()));
  sl.registerLazySingleton(() => CreateOtp(sl()));
  sl.registerLazySingleton(() => UpdateOtp(sl()));
  sl.registerLazySingleton(() => DeleteOtp(sl()));
  sl.registerLazySingleton(() => DeleteAllOtps(sl()));

  // Repository
  sl.registerLazySingleton<OtpRepo>(() => OtpRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<OtpRemoteDataSource>(
    () => OtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initEndTripChecklist() async {
  // BLoC
  sl.registerLazySingleton(
    () => EndTripChecklistBloc(
      generateEndTripChecklist: sl(),
      checkEndTripChecklist: sl(),
      loadEndTripChecklist: sl(),
      getAllEndTripChecklists: sl(),
      createEndTripChecklistItem: sl(),
      updateEndTripChecklistItem: sl(),
      deleteEndTripChecklistItem: sl(),
      deleteAllEndTripChecklistItems: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GenerateEndTripChecklist(sl()));
  sl.registerLazySingleton(() => CheckEndTripChecklist(sl()));
  sl.registerLazySingleton(() => LoadEndTripChecklist(sl()));
  sl.registerLazySingleton(() => GetAllEndTripChecklists(sl()));
  sl.registerLazySingleton(() => CreateEndTripChecklistItem(sl()));
  sl.registerLazySingleton(() => UpdateEndTripChecklistItem(sl()));
  sl.registerLazySingleton(() => DeleteEndTripChecklistItem(sl()));
  sl.registerLazySingleton(() => DeleteAllEndTripChecklistItems(sl()));

  // Repository
  sl.registerLazySingleton<EndTripChecklistRepo>(
    () => EndTripChecklistRepoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<EndTripChecklistRemoteDataSource>(
    () => EndTripChecklistRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initEndTripOtp() async {
  // BLoC
  sl.registerLazySingleton(
    () => EndTripOtpBloc(
      verifyEndTripOtp: sl(),
      getGeneratedEndTripOtp: sl(),
      loadEndTripOtpById: sl(),
      loadEndTripOtpByTripId: sl(),
      getAllEndTripOtps: sl(),
      createEndTripOtp: sl(),
      updateEndTripOtp: sl(),
      deleteEndTripOtp: sl(),
      deleteAllEndTripOtps: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => EndOTPVerify(sl()));
  sl.registerLazySingleton(() => GetEndTripGeneratedOtp(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpById(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpByTripId(sl()));
  sl.registerLazySingleton(() => GetAllEndTripOtps(sl()));
  sl.registerLazySingleton(() => CreateEndTripOtp(sl()));
  sl.registerLazySingleton(() => UpdateEndTripOtp(sl()));
  sl.registerLazySingleton(() => DeleteEndTripOtp(sl()));
  sl.registerLazySingleton(() => DeleteAllEndTripOtps(sl()));

  // Repository
  sl.registerLazySingleton<EndTripOtpRepo>(() => EndTripOtpRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<EndTripOtpRemoteDataSource>(
    () => EndTripOtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryUpdateStatus() async {
  // BLoC
  sl.registerLazySingleton(
    () => DeliveryUpdateBloc(
      getDeliveryStatusChoices: sl(),
      updateDeliveryStatus: sl(),
      checkEndDeliverStatus: sl(),
      initializePendingStatus: sl(),
      createDeliveryStatus: sl(),
      updateQueueRemarks: sl(),
      getAllDeliveryUpdates: sl(),
      createDeliveryUpdate: sl(),
      updateDeliveryUpdate: sl(),
      deleteDeliveryUpdate: sl(),
      deleteAllDeliveryUpdates: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetDeliveryStatusChoices(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => CheckEndDeliverStatus(sl()));
  sl.registerLazySingleton(() => InitializePendingStatus(sl()));
  sl.registerLazySingleton(() => CreateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => UpdateQueueRemarks(sl()));

  // New usecases
  sl.registerLazySingleton(() => GetAllDeliveryUpdates(sl()));
  sl.registerLazySingleton(() => CreateDeliveryUpdate(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryUpdate(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryUpdate(sl()));
  sl.registerLazySingleton(() => DeleteAllDeliveryUpdates(sl()));

  // Repository
  sl.registerLazySingleton<DeliveryUpdateRepo>(
    () => DeliveryUpdateRepoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<DeliveryUpdateDatasource>(
    () => DeliveryUpdateDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initReturns() async {
  // BLoC
  sl.registerLazySingleton(
    () => ReturnBloc(
      getReturns: sl(),
      getReturnByCustomerId: sl(),
      getAllReturns: sl(),
      createReturn: sl(),
      updateReturn: sl(),
      deleteReturn: sl(),
      deleteAllReturns: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetReturnUsecase(sl()));
  sl.registerLazySingleton(() => GetReturnByCustomerId(sl()));
  sl.registerLazySingleton(() => GetAllReturns(sl()));
  sl.registerLazySingleton(() => CreateReturn(sl()));
  sl.registerLazySingleton(() => UpdateReturn(sl()));
  sl.registerLazySingleton(() => DeleteReturn(sl()));
  sl.registerLazySingleton(() => DeleteAllReturns(sl()));

  // Repository
  sl.registerLazySingleton<ReturnRepo>(() => ReturnRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<ReturnRemoteDatasource>(
    () => ReturnRemoteDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initTripUpdate() async {
  // BLoC
  sl.registerLazySingleton(
    () => TripUpdatesBloc(
      getTripUpdates: sl(),
      getAllTripUpdates: sl(),
      createTripUpdate: sl(),
      updateTripUpdate: sl(),
      deleteTripUpdate: sl(),
      deleteAllTripUpdates: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetTripUpdates(sl()));
  sl.registerLazySingleton(() => GetAllTripUpdates(sl()));
  sl.registerLazySingleton(() => CreateTripUpdate(sl()));
  sl.registerLazySingleton(() => UpdateTripUpdate(sl()));
  sl.registerLazySingleton(() => DeleteTripUpdate(sl()));
  sl.registerLazySingleton(() => DeleteAllTripUpdates(sl()));

  // Repository
  sl.registerLazySingleton<TripUpdateRepo>(() => TripUpdateRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<TripUpdateRemoteDatasource>(
    () => TripUpdateRemoteDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initTrip() async {
  // BLoC
  sl.registerLazySingleton(
    () => TripBloc(
      getAllTripTickets: sl(),
      createTripTicket: sl(),
      searchTripTickets: sl(),
      getTripTicketById: sl(),
      updateTripTicket: sl(),
      deleteTripTicket: sl(),
      deleteAllTripTickets: sl(),
      filterTripsByDateRange: sl(),
      filterTripsByUser: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAllTripTickets(sl()));
  sl.registerLazySingleton(() => CreateTripTicket(sl()));
  sl.registerLazySingleton(() => SearchTripTickets(sl()));
  sl.registerLazySingleton(() => GetTripTicketById(sl()));
  sl.registerLazySingleton(() => UpdateTripTicket(sl()));
  sl.registerLazySingleton(() => DeleteTripTicket(sl()));
  sl.registerLazySingleton(() => DeleteAllTripTickets(sl()));
  sl.registerLazySingleton(() => FilterTripsByDateRange(sl())); // (start, end
  sl.registerLazySingleton(() => FilterTripsByUser(sl())); // (userId,)

  // Repository
  sl.registerLazySingleton<TripRepo>(() => TripRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<TripRemoteDatasurce>(
    () => TripRemoteDatasurceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initTripCoordinatesUpdate() async {
  sl.registerLazySingleton(
    () => TripCoordinatesUpdateBloc(getTripCoordinatesByTripId: sl()),
  );

  sl.registerLazySingleton(() => GetTripCoordinatesByTripId(sl()));

  sl.registerLazySingleton<TripCoordinatesRemoteDataSource>(
    () => TripCoordinatesRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<TripCoordinatesRepo>(
    () => TripCoordinatesRepoImpl(sl()),
  );
}

Future<void> initCustomerData() async {
  sl.registerLazySingleton(
    () => CustomerDataBloc(
      getAllCustomerData: sl(),
      getCustomerDataById: sl(),
      createCustomerData: sl(),
      updateCustomerData: sl(),
      deleteCustomerData: sl(),
      deleteAllCustomerData: sl(),
      addCustomerToDelivery: sl(),
      getCustomersByDeliveryId: sl(), getAllUnassignedCustomerData: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAllCustomerData(sl()));
  sl.registerLazySingleton(() => GetCustomerDataById(sl()));
  sl.registerLazySingleton(() => CreateCustomerData(sl()));
  sl.registerLazySingleton(() => UpdateCustomerData(sl()));
  sl.registerLazySingleton(() => DeleteCustomerData(sl()));
  sl.registerLazySingleton(() => DeleteAllCustomerData(sl()));
  sl.registerLazySingleton(() => AddCustomerToDelivery(sl()));
  sl.registerLazySingleton(() => GetCustomersByDeliveryId(sl()));
  sl.registerLazySingleton(() => GetAllUnassignedCustomerData(sl()));

  sl.registerLazySingleton<CustomerDataRepo>(() => CustomerDataRepoImpl(sl()));
  sl.registerLazySingleton<CustomerDataRemoteDataSource>(
    () => CustomerDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initInvoiceData() async {
  sl.registerLazySingleton(
    () => InvoiceDataBloc(
      getAllInvoiceData: sl(),
      getInvoiceDataById: sl(),
      getInvoiceDataByDeliveryId: sl(),
      getInvoiceDataByCustomerId: sl(),
      addInvoiceDataToDelivery: sl(),
      addInvoiceDataToInvoiceStatus: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAllInvoiceData(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataByCustomerId(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataById(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataByDeliveryId(sl()));
  sl.registerLazySingleton(() => AddInvoiceDataToDelivery(sl()));
  sl.registerLazySingleton(() => AddInvoiceDataToInvoiceStatus(sl()));

  sl.registerLazySingleton<InvoiceDataRepo>(() => InvoiceDataRepoImpl(sl()));
  sl.registerLazySingleton<InvoiceDataRemoteDataSource>(
    () => InvoiceDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

// Add this function to the init section
Future<void> initInvoiceItems() async {
  // BLoC
  sl.registerLazySingleton(
    () => InvoiceItemsBloc(
      getInvoiceItemsByInvoiceDataId: sl(),
      getAllInvoiceItems: sl(),
      updateInvoiceItemById: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetInvoiceItemsByInvoiceDataId(sl()));
  sl.registerLazySingleton(() => GetAllInvoiceItems(sl()));
  sl.registerLazySingleton(() => UpdateInvoiceItemById(sl()));

  // Repository
  sl.registerLazySingleton<InvoiceItemsRepo>(() => InvoiceItemsRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<InvoiceItemsRemoteDataSource>(
    () => InvoiceItemsRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

// Add this function to initialize the InvoicePresetGroup feature
Future<void> initInvoicePresetGroup() async {
  // BLoC
  sl.registerLazySingleton(
    () => InvoicePresetGroupBloc(
      getAllInvoicePresetGroups: sl(),
      addAllInvoicesToDelivery: sl(),
      searchPresetGroupByRefId: sl(),
      getAllUnassignedInvoices: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAllInvoicePresetGroups(sl()));
  sl.registerLazySingleton(() => AddAllInvoicesToDelivery(sl()));
  sl.registerLazySingleton(() => SearchPresetGroupByRefId(sl()));
  sl.registerLazySingleton(() => GetAllUnassignedInvoices(sl()));

  // Repository
  sl.registerLazySingleton<InvoicePresetGroupRepo>(
    () => InvoicePresetGroupRepoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<InvoicePresetGroupRemoteDataSource>(
    () => InvoicePresetGroupRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

// Add this function to initialize the DeliveryData feature
Future<void> initDeliveryData() async {
  // BLoC
  sl.registerLazySingleton(
    () => DeliveryDataBloc(
      getAllDeliveryData: sl(),
      getDeliveryDataByTripId: sl(),
      getDeliveryDataById: sl(),
      deleteDeliveryData: sl(),
      getAllDeliveryDataWithTrips: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAllDeliveryData(sl()));
  sl.registerLazySingleton(() => GetDeliveryDataByTripId(sl()));
  sl.registerLazySingleton(() => GetDeliveryDataById(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryData(sl()));
  sl.registerLazySingleton(() => GetAllDeliveryDataWithTrips(sl()));

  // Repository
  sl.registerLazySingleton<DeliveryDataRepo>(() => DeliveryDataRepoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<DeliveryDataRemoteDataSource>(
    () => DeliveryDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryVehicleData() async {
  sl.registerLazySingleton(
    () => DeliveryVehicleBloc(
      loadDeliveryVehicleById: sl(),
      loadDeliveryVehiclesByTripId: sl(),
      loadAllDeliveryVehicles: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadDeliveryVehicleById(sl()));
  sl.registerLazySingleton(() => LoadDeliveryVehiclesByTripId(sl()));
  sl.registerLazySingleton(() => LoadAllDeliveryVehicles(sl()));

  sl.registerLazySingleton<DeliveryVehicleRepo>(
    () => DeliveryVehicleRepoImpl(sl()),
  );

  sl.registerLazySingleton<DeliveryVehicleRemoteDataSource>(
    () => DeliveryVehicleRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryCollectionsData() async {
  sl.registerLazySingleton(
    () => CollectionsBloc(
      deleteCollection: sl(),
      getCollectionById: sl(),
      getCollectionsByTripId: sl(),
      getAllCollections: sl(),
      filterCollectionsByDate: sl(),
    ),
  );

  sl.registerLazySingleton(() => DeleteCollection(sl()));
  sl.registerLazySingleton(() => GetCollectionById(sl()));
  sl.registerLazySingleton(() => GetCollectionsByTripId(sl()));
  sl.registerLazySingleton(() => GetAllCollections(sl()));
  sl.registerLazySingleton(() => FilterCollectionsByDate(sl()));

  sl.registerLazySingleton<CollectionRepo>(
    () => CollectionRepoImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CollectionRemoteDataSource>(
    () => CollectionRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initCancelledInvoiceData() async {
  sl.registerLazySingleton(
    () => CancelledInvoiceBloc(
      loadCancelledInvoicesByTripId: sl(),
      loadCancelledInvoicesById: sl(),
      createCancelledInvoiceByDeliveryDataId: sl(),
      deleteCancelledInvoice: sl(),
      getAllCancelledInvoices: sl(),
      reassignTripForCancelledInvoice: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadCancelledInvoicesByTripId(sl()));
  sl.registerLazySingleton(() => LoadCancelledInvoiceById(sl()));
  sl.registerLazySingleton(() => CreateCancelledInvoiceByDeliveryDataId(sl()));
  sl.registerLazySingleton(() => DeleteCancelledInvoice(sl()));
  sl.registerLazySingleton(() => GetAllCancelledInvoices(sl()));
  sl.registerLazySingleton(() => ReassignTripForCancelledInvoice(sl()));

  sl.registerLazySingleton<CancelledInvoiceRepo>(
    () => CancelledInvoiceRepoImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CancelledInvoiceRemoteDataSource>(
    () => CancelledInvoiceRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryReceipt() async {
  sl.registerLazySingleton(
    () => DeliveryReceiptBloc(
      getDeliveryReceiptByTripId: sl(),
      getDeliveryReceiptByDeliveryDataId: sl(),
      createDeliveryReceipt: sl(),
      deleteDeliveryReceipt: sl(),
      generateDeliveryReceiptPdf: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetDeliveryReceiptByTripId(sl()));
  sl.registerLazySingleton(() => GetDeliveryReceiptByDeliveryDataId(sl()));
  sl.registerLazySingleton(() => CreateDeliveryReceipt(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryReceipt(sl()));
  sl.registerLazySingleton(() => GenerateDeliveryReceiptPdf(sl()));

  sl.registerLazySingleton<DeliveryReceiptRepo>(
    () => DeliveryReceiptRepoImpl(remoteDatasource: sl()),
  );

  sl.registerLazySingleton<DeliveryReceiptRemoteDatasource>(
    () => DeliveryReceiptRemoteDatasourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initPersonnelTrip() async {
  // BLoC
  sl.registerLazySingleton(
    () => PersonnelTripBloc(
      getAllPersonnelTrips: sl(),
      getPersonnelTripById: sl(),
      getPersonnelTripsByPersonnelId: sl(),
      getPersonnelTripsByTripId: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAllPersonnelTrips(sl()));
  sl.registerLazySingleton(() => GetPersonnelTripById(sl()));
  sl.registerLazySingleton(() => GetPersonnelTripsByPersonnelId(sl()));
  sl.registerLazySingleton(() => GetPersonnelTripsByTripId(sl()));

  // Repository
  sl.registerLazySingleton<PersonnelTripRepo>(
    () => PersonnelTripRepoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<PersonnelTripRemoteDataSource>(
    () => PersonnelTripRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}
