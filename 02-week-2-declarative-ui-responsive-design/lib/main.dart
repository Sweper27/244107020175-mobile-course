import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Poin 3: Pindahkan breakpoint ke satu konstanta bernama
const double kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 4),
              Semantics(
                label: 'Beralih mode gelap',
                hint: 'Ketuk dua kali untuk mengubah tema aplikasi',
                toggled: isDark,
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ProfileHeaderCard(),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Menggunakan konstanta breakpoint
                final columns =
                    constraints.maxWidth >= kWideBreakpoint ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    // Poin 1: Menggunakan InfoCard yang reusable
                    InfoCard(title: 'Assignments', value: '8'),
                    InfoCard(title: 'Attendance', value: '92%'),
                    InfoCard(title: 'Portfolio', value: 'Ready'),
                    InfoCard(title: 'Current week', value: '02'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Poin 2: Menggunakan Theme.of(context)
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Profil Mahasiswa: Rifqi Aries Saputra',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama Mahasiswa',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rifqi Aries Saputra',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('NIM')),
                Text('230000000', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: Text('Email')),
                Text('Rifqiariessa...', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: Text('Kelas')),
                Text('3A', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Poin 1: Widget Reusable InfoCard
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Poin 2: Menggunakan Theme.of(context) untuk warna & ukuran teks
    final theme = Theme.of(context);

    return Semantics(
      label: 'Kartu $title, nilainya adalah $value',
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}