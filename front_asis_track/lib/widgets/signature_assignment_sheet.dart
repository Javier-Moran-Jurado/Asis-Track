import 'package:flutter/material.dart';

import '../models/student_record.dart';
import '../themes/app_theme.dart';

class SignatureAssignmentSheet extends StatelessWidget {
  final List<StudentRecord> records;
  final ValueChanged<int> onSelect;

  const SignatureAssignmentSheet({
    super.key,
    required this.records,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Asignar firma',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  title: Text(record.nombreCompleto),
                  subtitle: Text('Cédula: ${record.cedula}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
