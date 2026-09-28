import 'package:app_barbershop_booking/src/screens/bookings/appointment_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'appointment detail resolves the selected Carlos from the API staff relation',
    () {
      final booking = <String, dynamic>{
        'id': 4,
        'staff_id': 1,
        'staff': <String, dynamic>{'id': 1, 'name': 'Carlos Ramírez'},
      };

      expect(appointmentBarber(booking)['id'], 1);
      expect(appointmentBarberName(booking), 'Carlos Ramírez');
    },
  );
}
