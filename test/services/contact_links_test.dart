import 'package:app_barbershop_booking/src/services/contact_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WhatsApp adds the Costa Rica code to 8-digit local numbers', () {
    expect(
      ContactLinks.whatsapp('8888-1111').toString(),
      'https://wa.me/50688881111',
    );
    expect(
      ContactLinks.whatsapp('+506 8888 1111').toString(),
      'https://wa.me/50688881111',
    );
    expect(ContactLinks.whatsapp(''), isNull);
  });

  test('phone keeps digits and a leading plus', () {
    expect(ContactLinks.phone('+506 2222-3333').toString(), 'tel:+50622223333');
    expect(ContactLinks.phone(' - '), isNull);
  });

  test('maps searches the business address', () {
    final uri = ContactLinks.maps('Puntarenas, El Roble')!;
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['query'], 'Puntarenas, El Roble');
    expect(ContactLinks.maps('  '), isNull);
  });

  test('instagram accepts a handle, a bare domain or a full URL', () {
    const expected = 'https://www.instagram.com/barberia3amigos';
    expect(ContactLinks.instagram('@barberia3amigos').toString(), expected);
    expect(
      ContactLinks.instagram('instagram.com/barberia3amigos/').toString(),
      expected,
    );
    expect(
      ContactLinks.instagram('https://instagram.com/x').toString(),
      'https://instagram.com/x',
    );
    expect(ContactLinks.instagram(''), isNull);
  });
}
