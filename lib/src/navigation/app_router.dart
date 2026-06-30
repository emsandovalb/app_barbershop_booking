import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/forgot_password_page.dart';
import '../screens/auth/reset_password_page.dart';
import '../screens/auth/change_password_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/home/home_shell.dart';
import '../screens/business/business_profile_page.dart';
import '../screens/bookings/booking_detail_page.dart';
import '../screens/bookings/ground_booking_detail_page.dart';
import '../screens/booking/payment_page.dart';
import '../screens/booking/order_placed_page.dart';
import '../screens/grounds/my_grounds_page.dart';
import '../screens/grounds/add_ground_page.dart';
import '../screens/grounds/add_photos_page.dart';
import '../screens/common/coming_soon_page.dart';
import '../screens/admin/admin_reservations_page.dart';
import '../screens/admin/admin_staff_page.dart';
import '../screens/admin/staff_form_page.dart';
import '../screens/admin/staff_resource_assignment_page.dart';
import '../screens/staff/staff_detail_page.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgot = '/auth/forgot';
  static const resetPassword = '/auth/reset';
  static const changePassword = '/auth/password-change';
  static const signup = '/signup';
  static const home = '/home';
  static const businessProfile = '/business/profile';
  static const bookingDetail = '/booking/detail';
  static const payment = '/booking/payment';
  static const orderPlaced = '/booking/order-placed';
  static const bookingShow = '/bookings/show';
  static const myGrounds = '/grounds/mine';
  static const addGround = '/grounds/add';
  static const categoryGround = '/grounds/category';
  static const addPhotos = '/grounds/photos';
  static const categories = '/categories';
  static const tournaments = '/tournaments';
  static const tournamentDetail = '/tournaments/detail';
  static const tournamentForm = '/tournaments/form';
  static const myTeams = '/teams';
  static const teamForm = '/teams/form';
  static const comingSoon = '/coming-soon';
  static const adminReservations = '/admin/reservations';
  static const adminStaff = '/admin/staff';
  static const staffForm = '/admin/staff/form';
  static const staffResourceAssignment = '/admin/staff/resources';
  static const staffDetail = '/staff/detail';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _material(settings, const SplashScreen());
      case AppRoutes.onboarding:
        return _material(settings, const OnboardingPage());
      case AppRoutes.login:
        return _material(settings, const LoginPage());
      case AppRoutes.forgot:
        return _material(settings, const ForgotPasswordPage());
      case AppRoutes.resetPassword:
        return _material(settings, const ResetPasswordPage());
      case AppRoutes.changePassword:
        return _material(settings, const ChangePasswordPage());
      case AppRoutes.signup:
        return _material(settings, const SignUpPage());
      case AppRoutes.home:
        return _material(settings, const HomeShell());
      case AppRoutes.businessProfile:
        return _material(settings, const BusinessProfilePage());
      case AppRoutes.bookingDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _material(settings, GroundBookingDetailPage(args: args));
      case AppRoutes.payment:
        final args = settings.arguments as Map<String, dynamic>;
        return _material(settings, PaymentPage(args: args));
      case AppRoutes.orderPlaced:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(settings, OrderPlacedPage(
          title: args['title'] as String? ?? 'Cita confirmada',
          subtitle: args['subtitle'] as String? ?? 'Tu cita fue confirmada correctamente.',
          buttonText: args['buttonText'] as String? ?? 'Volver al inicio',
          backRoute: args['backRoute'] as String? ?? AppRoutes.home,
        ));
      case AppRoutes.bookingShow:
        final args = settings.arguments as Map<String, dynamic>;
        return _material(settings, BookingDetailPage(booking: args['booking'] as Map<String, dynamic>));
      case AppRoutes.myGrounds:
        return _material(settings, const MyGroundsPage());
      case AppRoutes.addGround:
        return _material(settings, const AddGroundPage());
      case AppRoutes.categoryGround:
        return _material(settings, const ComingSoonPage(title: 'Service categories unavailable'));
      case AppRoutes.addPhotos:
        final args = settings.arguments as Map<String, dynamic>?;
        return _material(settings, AddPhotosPage(initialData: args ?? const {}));
      case AppRoutes.categories:
        return _material(settings, const ComingSoonPage(title: 'Service categories unavailable'));
      case AppRoutes.tournaments:
        return _material(settings, const ComingSoonPage(title: 'Promotions unavailable'));
      case AppRoutes.tournamentDetail:
        return _material(settings, const ComingSoonPage(title: 'Promotions unavailable'));
      case AppRoutes.tournamentForm:
        return _material(settings, const ComingSoonPage(title: 'Promotions unavailable'));
      case AppRoutes.myTeams:
        return _material(settings, const ComingSoonPage(title: 'Teams unavailable'));
      case AppRoutes.teamForm:
        return _material(settings, const ComingSoonPage(title: 'Teams unavailable'));
      case AppRoutes.comingSoon:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(settings, ComingSoonPage(title: args['title'] as String?));
      case AppRoutes.adminReservations:
        return _material(settings, const AdminReservationsPage());
      case AppRoutes.adminStaff:
        return _material(settings, const AdminStaffPage());
      case AppRoutes.staffForm:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(
          settings,
          StaffFormPage(
            staff: args['staff'] as Map<String, dynamic>?,
          ),
        );
      case AppRoutes.staffResourceAssignment:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(
          settings,
          StaffResourceAssignmentPage(
            staffId: args['staff_id'] as int,
            initialStaff: args['staff'] as Map<String, dynamic>?,
          ),
        );
      case AppRoutes.staffDetail:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        final staff = args['staff'];
        return _material(
          settings,
          StaffDetailPage(
            staff: staff is Map
                ? Map<String, dynamic>.from(staff)
                : const <String, dynamic>{},
          ),
        );
      default:
        return _material(settings, const SplashScreen());
    }
  }

  static MaterialPageRoute _material(RouteSettings settings, Widget child) =>
      MaterialPageRoute(settings: settings, builder: (_) => child);
}
