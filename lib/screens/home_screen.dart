import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A minimal starter screen that showcases the MediCarry theme: display and
/// body typography, primary/secondary buttons, a filled input, and a card.
/// Replace this with real screens as the app grows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediCarry'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Morning, Sarah', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Here is your health overview for today.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // Accent (lime) hero card — mirrors the "next medication" card.
              _HeroCard(colors: colors, theme: theme),
              const SizedBox(height: 16),

              // Navy stat card.
              _StatCard(colors: colors, theme: theme),
              const SizedBox(height: 24),

              Text('Quick actions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search records…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Record'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {},
                child: const Text('Emergency Info'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('View all activity'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT MEDICATION',
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Lisinopril',
            style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.ink),
          ),
          Text(
            '10mg · Take with food',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.ink.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: AppColors.lime),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LATEST BP',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                '118/76',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
