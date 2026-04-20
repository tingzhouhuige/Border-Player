import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile(
      {super.key, required this.description, required this.action});

  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 74,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            description,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 19.0,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: action,
          ),
        ],
      ),
    );
  }
}
