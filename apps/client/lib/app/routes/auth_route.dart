import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_scope.dart';
import '../auth/auth_store.dart';

class AuthRoute extends StatefulWidget {
  const AuthRoute({super.key});

  @override
  State<AuthRoute> createState() => _AuthRouteState();
}

class _AuthRouteState extends State<AuthRoute> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthMode _mode = AuthMode.login;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authStore = AuthScope.of(context);
    final session = authStore.session;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.authBody,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SegmentedButton<AuthMode>(
            segments: [
              ButtonSegment<AuthMode>(
                value: AuthMode.login,
                label: Text(l10n.authLoginAction),
              ),
              ButtonSegment<AuthMode>(
                value: AuthMode.register,
                label: Text(l10n.authRegisterAction),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
              });
            },
          ),
          const SizedBox(height: 24),
          if (!authStore.isRemoteEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l10n.authUnavailableTitle),
                subtitle: Text(l10n.authUnavailableBody),
              ),
            )
          else if (session != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(session.email),
                subtitle: Text(
                  l10n.authSignedInBody(session.expiresAt.toLocal().toString()),
                ),
                trailing: TextButton(
                  onPressed: authStore.isSubmitting ? null : authStore.logout,
                  child: Text(l10n.authLogoutAction),
                ),
              ),
            )
          else ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.authEmailLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.authPasswordLabel),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: authStore.isSubmitting
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await authStore.submit(
                        mode: _mode,
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                      if (!mounted) {
                        return;
                      }
                      if (authStore.session != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.authSuccess)),
                        );
                      }
                    },
              child: Text(
                authStore.isSubmitting
                    ? l10n.authSubmitting
                    : (_mode == AuthMode.login
                        ? l10n.authLoginAction
                        : l10n.authRegisterAction),
              ),
            ),
          ],
          if (authStore.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              authStore.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
