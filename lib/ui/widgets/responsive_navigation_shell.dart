import 'package:flutter/material.dart';

import '../app_theme.dart';

enum AppDestination { library, search, settings }

class ResponsiveNavigationShell extends StatelessWidget {
  final AppDestination destination;
  final ValueChanged<AppDestination> onDestinationChanged;
  final PreferredSizeWidget? appBar;
  final Widget body;

  const ResponsiveNavigationShell({
    super.key,
    required this.destination,
    required this.onDestinationChanged,
    required this.body,
    this.appBar,
  });

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.library_books_outlined),
      selectedIcon: Icon(Icons.library_books),
      label: 'Biblioteca',
    ),
    NavigationDestination(
      icon: Icon(Icons.search),
      label: 'Buscar',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune),
      label: 'Ajustes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIndex = destination.index;
        if (constraints.maxWidth >= AppBreakpoints.wide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  key: const Key('wide-navigation-rail'),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      onDestinationChanged(AppDestination.values[index]),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: NavigationBar(
            key: const Key('compact-bottom-navigation'),
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                onDestinationChanged(AppDestination.values[index]),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
