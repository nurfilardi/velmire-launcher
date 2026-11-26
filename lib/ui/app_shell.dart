import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'data_page.dart';
import 'home_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                _TabItem(
                  icon: Icons.route_outlined,
                  activeIcon: Icons.route,
                  label: 'Rute',
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
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Palette.surfaceHi : Colors.transparent,
            border: Border.all(
              color: selected ? Palette.signal : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected ? Palette.signal : Palette.muted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 10,
                  letterSpacing: 0.3,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Palette.ink : Palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
