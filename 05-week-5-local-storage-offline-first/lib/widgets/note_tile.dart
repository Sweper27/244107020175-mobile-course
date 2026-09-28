import 'package:flutter/material.dart';

import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onDelete,
    this.onTap,
  });

  final Note note;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // Seluruh catatan bisa ditekan
        onTap: onTap,

        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (note.dirty)
                  const Chip(
                    label: Text(
                      'Belum tersinkron',
                    ),
                    avatar: Icon(
                      Icons.cloud_off,
                      size: 18,
                    ),
                  ),

                Text(
                  _formatDate(note.updatedAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ],
        ),

        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final day = local.day
        .toString()
        .padLeft(2, '0');

    final month = local.month
        .toString()
        .padLeft(2, '0');

    final year = local.year;

    final hour = local.hour
        .toString()
        .padLeft(2, '0');

    final minute = local.minute
        .toString()
        .padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}