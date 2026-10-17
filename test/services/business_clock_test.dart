import 'package:app_barbershop_booking/src/screens/bookings/appointment_helpers.dart';
import 'package:app_barbershop_booking/src/services/business_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-10-20 16:00 UTC is 10:00 in Costa Rica (UTC-6).
  final morningUtc = DateTime.utc(2026, 10, 20, 16);

  setUp(() {
    BusinessClock.configureFrom({'utc_offset_minutes': -360});
    BusinessClock.debugOverride(
      utcOffset: const Duration(minutes: -360),
      utcNow: morningUtc,
    );
  });

  tearDown(BusinessClock.debugReset);

  test('now is the business wall clock regardless of the device zone', () {
    expect(BusinessClock.now(), DateTime.utc(2026, 10, 20, 10));
    expect(BusinessClock.today(), DateTime(2026, 10, 20));
  });

  test('today stays on the local date after UTC midnight', () {
    BusinessClock.debugOverride(
      utcOffset: const Duration(minutes: -360),
      utcNow: DateTime.utc(2026, 10, 21, 3),
    );

    expect(BusinessClock.today(), DateTime(2026, 10, 20));
  });

  test('configureFrom reads the offset from an app-config payload', () {
    BusinessClock.debugReset();
    BusinessClock.configureFrom({'utc_offset_minutes': '-300'});

    expect(BusinessClock.utcOffset, const Duration(minutes: -300));
  });

  test('appointment dates with or without Z read as wall-clock time', () {
    expect(
      BusinessClock.parseAppointment('2026-10-20T14:00:00.000000Z'),
      DateTime.utc(2026, 10, 20, 14),
    );
    expect(
      BusinessClock.parseAppointment('2026-10-20T14:00:00'),
      DateTime.utc(2026, 10, 20, 14),
    );
    expect(BusinessClock.parseAppointment(null), isNull);
  });

  test('an afternoon appointment is upcoming in the local morning', () {
    final booking = {
      'status': 'confirmed',
      'date': '2026-10-20T15:00:00.000000Z',
    };

    // Compared on the UTC clock, 15:00 would already be in the past.
    expect(appointmentStatusBucket(booking), AppointmentStatusBucket.upcoming);
    expect(canCancelAppointment(booking, windowHours: 4), isTrue);
  });

  test('cancellation closes four hours before the local start', () {
    final booking = {
      'status': 'confirmed',
      'date': '2026-10-20T13:00:00.000000Z',
    };

    expect(canCancelAppointment(booking, windowHours: 4), isFalse);
  });

  test('the business window decides, not a fixed 4 hours', () {
    final booking = {
      'status': 'confirmed',
      'date': '2026-10-20T15:00:00.000000Z',
    };

    // Five hours ahead of the local 10:00.
    expect(canCancelAppointment(booking, windowHours: 2), isTrue);
    expect(canCancelAppointment(booking, windowHours: 24), isFalse);
  });
}
