import 'package:flutter/material.dart';

import 'data_page.dart';
import 'home_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openServers() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenServers: _openServers),
      const ServersPage(),
      const DataPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Palette.bg,
          border: Border(top: BorderSide(color: Palette.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _TabItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _TabItem(
                  icon: Icons.dns_outlined,
                  activeIcon: Icons.dns,
                  label: 'Server',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _TabItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  label: 'Data',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _TabItem(
                  icon: Icons.tune,
                  activeIcon: Icons.tune,
                  label: 'Setelan',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.accent : Palette.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 21, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 9.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: selected ? 16 : 0,
              height: 2,
              color: Palette.accent,
            ),
          ],
        ),
      ),
    );
  }
}
