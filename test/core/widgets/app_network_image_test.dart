import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_network_image.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(setUpTestConfig);

  testWidgets('empty or non-http URLs show the error look without loading', (tester) async {
    await pumpTestApp(
      tester,
      const Column(children: [AppNetworkImage('', width: 40, height: 40), AppNetworkImage(null)]),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNWidgets(2));
  });

  testWidgets('valid URLs go through the cache', (tester) async {
    expect(AppNetworkImage.isValidUrl('https://x.test/a.png'), isTrue);
    expect(AppNetworkImage.isValidUrl('ftp://x.test/a.png'), isFalse);
  });

  testWidgets('avatar falls back to the uppercase initial', (tester) async {
    await pumpTestApp(tester, const AppAvatar(url: null, name: 'emily Johnson'));
    expect(find.text('E'), findsOneWidget);
  });
}
