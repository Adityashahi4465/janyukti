import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'shared/mock_data/app_store.dart';

void main() => runApp(JanYukti(store: AppStore()));

class JanYukti extends StatelessWidget {
  const JanYukti({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => StoreScope(
    store: store,
    child: MaterialApp(
      title: 'CIVORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.welcome,
      onGenerateRoute: AppRoutes.generate,
    ),
  );
}
