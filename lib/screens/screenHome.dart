import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sidebarx/sidebarx.dart';

const sidebarPinkColor = Color(0xFFF47FA1);
const sidebarPinkHoverColor = Color(0xFFEA6B90);
const creamHeaderColor = Color(0xFFF8F2DD);

String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Inicio';
    case 1:
      return 'Empleados';
    case 2:
      return 'Cerdas';
    case 3:
      return 'Reproducción';
    case 4:
      return 'Partos';
    case 5:
      return 'Destete';
    case 6:
      return 'Reportes';
    default:
      return 'Página no encontrada';
  }
}

Widget _buildLogoWidget({double height = 36}) {
  return Image.asset(
    'assets/imgs/logo.png',
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => const Text(
      'PORCILAC',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  final _controller = SidebarXController(selectedIndex: 1, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    key: _key,
    backgroundColor: creamHeaderColor,
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExampleSidebarX(controller: _controller),
        Expanded(
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  height: 54,
                  color: creamHeaderColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: _buildLogoWidget(height: 32),
                      ),
                      const SizedBox(width: 6),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications,
                            size: 18,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: _ScreensExample(controller: _controller),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}


class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    super.key,
    required SidebarXController controller,
  }) : _controller = controller;

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final expandedWidth = isCompact ? 154.0 : 185.0;
    final collapsedWidth = isCompact ? 56.0 : 66.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isCollapsed = !_controller.extended;

        return SidebarX(
          controller: _controller,
          showToggleButton: false,
          theme: SidebarXTheme(
            decoration: const BoxDecoration(color: sidebarPinkColor),
            width: collapsedWidth,
            itemPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            selectedItemPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemTextPadding: const EdgeInsets.only(left: 10),
            selectedItemTextPadding: const EdgeInsets.only(left: 10),
            hoverColor: sidebarPinkHoverColor,
            textStyle: TextStyle(
              color: Colors.black87,
              fontSize: isCompact ? 12.5 : 13,
              fontWeight: FontWeight.w500,
            ),
            selectedTextStyle: TextStyle(
              color: Colors.black,
              fontSize: isCompact ? 12.5 : 13,
              fontWeight: FontWeight.bold,
            ),
            hoverTextStyle: TextStyle(
              color: Colors.black,
              fontSize: isCompact ? 12.5 : 13,
              fontWeight: FontWeight.w600,
            ),
            itemDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
            ),
            selectedItemDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            iconTheme: const IconThemeData(
              color: Colors.black87,
              size: 18,
            ),
            selectedIconTheme: const IconThemeData(
              color: Colors.black,
              size: 18,
            ),
          ),
          extendedTheme: SidebarXTheme(
            width: expandedWidth,
            decoration: const BoxDecoration(color: sidebarPinkColor),
          ),
          headerBuilder: (context, extended) {
            return SafeArea(
              bottom: false,
              child: Container(
                height: 54,
                width: double.infinity,
                color: sidebarPinkColor,
                alignment:
                    extended ? Alignment.centerLeft : Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                child: IconButton(
                  tooltip: extended ? 'Contraer menú' : 'Expandir menú',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.black87,
                    size: 21,
                  ),
                  onPressed: () {
                    _controller.setExtended(!_controller.extended);
                  },
                ),
              ),
            );
          },
          footerBuilder: (context, extended) {
            final footerContent = SafeArea(
              top: false,
              child: InkWell(
                onTap: () => debugPrint('Cerrar sesión'),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: extended ? 12 : 8,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: extended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout,
                        color: Colors.black87,
                        size: 18,
                      ),
                      if (extended) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: isCompact ? 12.5 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            if (!isCollapsed) return footerContent;

            return _wrapWithTooltip(
              label: 'Cerrar sesión',
              child: footerContent,
            );
          },
          items: [
            _buildSidebarItem(
              label: 'Inicio',
              icon: Icons.home_outlined,
              isCollapsed: isCollapsed,
              onTap: () => debugPrint('Inicio'),
            ),
            _buildSidebarItem(
              label: 'Empleados',
              icon: Icons.people,
              isCollapsed: isCollapsed,
            ),
            _buildSidebarItem(
              label: 'Cerdas',
              iconWidget: const FaIcon(
                FontAwesomeIcons.piggyBank,
                size: 16,
                color: Colors.black87,
              ),
              isCollapsed: isCollapsed,
            ),
            _buildSidebarItem(
              label: 'Reproducción',
              iconWidget: const FaIcon(
                FontAwesomeIcons.dna,
                size: 16,
                color: Colors.black87,
              ),
              isCollapsed: isCollapsed,
            ),
            _buildSidebarItem(
              label: 'Partos',
              icon: Icons.child_care,
              isCollapsed: isCollapsed,
            ),
            _buildSidebarItem(
              label: 'Destete',
              iconWidget: const FaIcon(
                FontAwesomeIcons.baby,
                size: 16,
                color: Colors.black87,
              ),
              isCollapsed: isCollapsed,
            ),
            _buildSidebarItem(
              label: 'Reportes',
              iconWidget: const FaIcon(
                FontAwesomeIcons.fileLines,
                size: 16,
                color: Colors.black87,
              ),
              isCollapsed: isCollapsed,
            ),
          ],
        );
      },
    );
  }

  SidebarXItem _buildSidebarItem({
    required String label,
    IconData? icon,
    Widget? iconWidget,
    required bool isCollapsed,
    VoidCallback? onTap,
  }) {
    final Widget baseIcon = iconWidget ??
        Icon(
          icon,
          size: 18,
          color: Colors.black87,
        );

    return SidebarXItem(
      label: label,
      onTap: onTap,
      iconWidget: isCollapsed
          ? _wrapWithTooltip(label: label, child: baseIcon)
          : baseIcon,
    );
  }

  Widget _wrapWithTooltip({
    required String label,
    required Widget child,
  }) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 180),
      preferBelow: false,
      verticalOffset: 0,
      margin: const EdgeInsets.only(left: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      child: child,
    );
  }
}

class _ScreensExample extends StatefulWidget {
  const _ScreensExample({
    required this.controller,
  });

  final SidebarXController controller;

  @override
  State<_ScreensExample> createState() => _ScreensExampleState();
}

class _ScreensExampleState extends State<_ScreensExample> {
  int _paginaActual = 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (widget.controller.selectedIndex == 1) {
          return _buildVistaEmpleados();
        }

        final pageTitle = _getTitleByIndex(widget.controller.selectedIndex);
        return Center(
          child: Text(
            pageTitle,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVistaEmpleados() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Empleados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => debugPrint('Nuevo empleado'),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text(
                  'Nuevo empleado',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDEBF1),
                  foregroundColor: const Color(0xFFE91E63),
                  side: const BorderSide(color: Color(0xFFF47FA1)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: Colors.black87),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: const BorderSide(color: sidebarPinkColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => debugPrint('Filtrar'),
                child: Container(
                  width: 44,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(Icons.filter_alt,
                      size: 18, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 86,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        width: double.infinity,
                        color: const Color(0xFFDCE1E8),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(Icons.edit,
                                size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(Icons.delete,
                                size: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 3; i++) ...[
                InkWell(
                  onTap: () => setState(() => _paginaActual = i),
                  child: Container(
                    width: 34,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _paginaActual == i ? sidebarPinkColor : Colors.white,
                      border: Border.all(
                        color: _paginaActual == i
                            ? sidebarPinkColor
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            _paginaActual == i ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}