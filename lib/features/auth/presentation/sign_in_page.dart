import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/auth_failure.dart';
import 'auth_providers.dart';

/// Pantalla de acceso. Es uno de los tres lugares donde aparece el degradado
/// de marca.
class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = context.text;
    final state = ref.watch(signInControllerProvider);
    final failure = state.error is AuthFailure
        ? state.error! as AuthFailure
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Iconos claros sobre el degradado, en ambos temas.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: c.surface,
      ),
      child: Scaffold(
        backgroundColor: c.surface,
        body: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: c.brandGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: FadeSlideIn(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandMark(size: 80, onGradient: true),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Master Pro',
                            style: text.displaySmall!.copyWith(
                              color: c.onGradient,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Tu centro de control académico',
                            style: text.bodyLarge!.copyWith(
                              color: c.onGradient.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xl,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                child: FadeSlideIn(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Entra con tu cuenta', style: text.titleLarge),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Tus asignaturas, entregas y notas se sincronizan '
                        'con ella. Los archivos se quedan en este teléfono.',
                        style: text.bodyMedium!.copyWith(color: c.inkSoft),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (failure != null) ...[
                        _FailureNotice(failure.message),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppButton(
                        label: 'Continuar con Google',
                        icon: LucideIcons.logIn,
                        expand: true,
                        loading: state.isLoading,
                        onPressed: ref
                            .read(signInControllerProvider.notifier)
                            .signIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.dangerContainer,
          borderRadius: AppRadii.md,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                size: 18,
                color: c.onDangerContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: context.text.bodyMedium!.copyWith(
                    color: c.onDangerContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Se muestra mientras se restaura la sesión guardada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Abriendo Master Pro',
          child: const BrandMark(),
        ),
      ),
    );
  }
}
