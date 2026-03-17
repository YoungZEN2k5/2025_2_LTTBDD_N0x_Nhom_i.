import 'package:flutter/material.dart';

import 'models.dart';
import 'main.dart';

enum TaskFilter { all, completed, pending, overdue }

enum _SortOrder { nearest, farthest }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.strings,
    required this.tasks,
    required this.categories,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final AppStrings strings;
  final List<TaskItem> tasks;
  final List<String> categories;
  final void Function(int index, bool? isCompleted) onToggleTask;
  final void Function(int index) onDeleteTask;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TaskFilter _activeFilter = TaskFilter.all;
  String _searchQuery = '';
  String _categoryFilter = '';
  _SortOrder _sortOrder = _SortOrder.nearest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isOverdue(TaskItem task, DateTime now) {
    return !task.isCompleted && task.deadline.isBefore(now);
  }

  String _twoDigits(int number) => number.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  Color _categoryColor(String category, bool isDark) {
    final int seed = category.hashCode.abs();
    final List<Color> light = <Color>[
      const Color(0xFF2F73D8),
      const Color(0xFFB35C00),
      const Color(0xFF1D8A65),
      const Color(0xFF7A3DB8),
      const Color(0xFFAF4C46),
    ];
    final List<Color> dark = <Color>[
      const Color(0xFF6CA6FF),
      const Color(0xFFFFB86A),
      const Color(0xFF8BE7C4),
      const Color(0xFFC6A0FF),
      const Color(0xFFFF9D95),
    ];
    return (isDark ? dark : light)[seed % light.length];
  }

  String _deadlineStateText(TaskItem task, DateTime now) {
    if (_isOverdue(task, now)) {
      return widget.strings.get('overdue');
    }

    final DateTime nowDate = DateTime(now.year, now.month, now.day);
    final DateTime taskDate = DateTime(
      task.deadline.year,
      task.deadline.month,
      task.deadline.day,
    );
    final int dayDifference = taskDate.difference(nowDate).inDays;

    if (dayDifference == 0) {
      return widget.strings.get('today');
    }

    return '${widget.strings.get('inDays')} $dayDifference ${widget.strings.get('days')}';
  }

  List<TaskItem> _filteredTasks(DateTime now) {
    final List<TaskItem> base;
    switch (_activeFilter) {
      case TaskFilter.all:
        base = widget.tasks;
      case TaskFilter.completed:
        base = widget.tasks.where((TaskItem task) => task.isCompleted).toList();
      case TaskFilter.pending:
        base = widget.tasks
            .where((TaskItem task) => !task.isCompleted)
            .toList();
      case TaskFilter.overdue:
        base = widget.tasks
            .where((TaskItem task) => _isOverdue(task, now))
            .toList();
    }

    final String query = _searchQuery.trim().toLowerCase();
    final List<TaskItem> searched = query.isEmpty
        ? List<TaskItem>.from(base)
        : base
              .where(
                (TaskItem task) => task.title.toLowerCase().contains(query),
              )
              .toList();

    final List<TaskItem> categoryFiltered = _categoryFilter.isEmpty
        ? searched
        : searched
              .where((TaskItem task) => task.category == _categoryFilter)
              .toList();

    categoryFiltered.sort(
      (TaskItem a, TaskItem b) => _sortOrder == _SortOrder.nearest
          ? a.deadline.compareTo(b.deadline)
          : b.deadline.compareTo(a.deadline),
    );
    return categoryFiltered;
  }

  int _indexOf(TaskItem task) {
    return widget.tasks.indexWhere((TaskItem item) => item.id == task.id);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime now = DateTime.now();

    final int completedCount = widget.tasks
        .where((TaskItem task) => task.isCompleted)
        .length;
    final int pendingCount = widget.tasks
        .where((TaskItem task) => !task.isCompleted)
        .length;
    final int overdueCount = widget.tasks
        .where((TaskItem task) => _isOverdue(task, now))
        .length;
    final List<TaskItem> visibleTasks = _filteredTasks(now);

    final List<(TaskFilter, String)> filters = <(TaskFilter, String)>[
      (TaskFilter.all, widget.strings.get('all')),
      (TaskFilter.completed, widget.strings.get('completed')),
      (TaskFilter.pending, widget.strings.get('notCompleted')),
      (TaskFilter.overdue, widget.strings.get('overdue')),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  const Color(0xFF10211C),
                  const Color(0xFF162A24),
                  const Color(0xFF1D352D),
                ]
              : <Color>[
                  const Color(0xFFD8EEE4),
                  const Color(0xFFF6F3EA),
                  const Color(0xFFF8F8F4),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              _HeroPanel(
                title: widget.strings.get('summaryTitle'),
                subtitle: widget.strings.get('homeSubtitle'),
                completedCount: completedCount,
                pendingCount: pendingCount,
                overdueCount: overdueCount,
                completedLabel: widget.strings.get('completed'),
                pendingLabel: widget.strings.get('notCompleted'),
                overdueLabel: widget.strings.get('overdue'),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.85),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (String v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: widget.strings.get('search'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ...filters.map(
                      ((TaskFilter, String) item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item.$2),
                          selected: _activeFilter == item.$1,
                          onSelected: (_) =>
                              setState(() => _activeFilter = item.$1),
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryFilter.isEmpty ? null : _categoryFilter,
                        hint: Text(widget.strings.get('category')),
                        items: widget.categories
                            .map(
                              (String category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _categoryFilter = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: widget.strings.get('sort'),
                      onPressed: () {
                        setState(() {
                          _sortOrder = _sortOrder == _SortOrder.nearest
                              ? _SortOrder.farthest
                              : _SortOrder.nearest;
                        });
                      },
                      icon: Icon(
                        _sortOrder == _SortOrder.nearest
                            ? Icons.north_rounded
                            : Icons.south_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: visibleTasks.isEmpty
                    ? _EmptyState(
                        title: widget.strings.get('emptyTitle'),
                        subtitle: widget.strings.get('emptySubtitle'),
                      )
                    : ListView.separated(
                        itemCount: visibleTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final TaskItem task = visibleTasks[index];
                          final int originalIndex = _indexOf(task);
                          if (originalIndex < 0) {
                            return const SizedBox.shrink();
                          }

                          final Color categoryColor = _categoryColor(
                            task.category,
                            isDark,
                          );
                          final bool overdue = _isOverdue(task, now);

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Checkbox(
                                    value: task.isCompleted,
                                    onChanged: (bool? value) => widget
                                        .onToggleTask(originalIndex, value),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          task.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: <Widget>[
                                            _MetaPill(
                                              icon: Icons.folder_open_rounded,
                                              text: task.category,
                                              backgroundColor: categoryColor
                                                  .withValues(alpha: 0.16),
                                              foregroundColor: categoryColor,
                                            ),
                                            _MetaPill(
                                              icon: overdue
                                                  ? Icons.error_outline_rounded
                                                  : Icons.schedule_rounded,
                                              text: _deadlineStateText(
                                                task,
                                                now,
                                              ),
                                              backgroundColor: overdue
                                                  ? const Color(
                                                      0xFFCF4A3A,
                                                    ).withValues(alpha: 0.16)
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                              foregroundColor: overdue
                                                  ? const Color(0xFFCF4A3A)
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${widget.strings.get('dueLabel')}: ${_formatDateTime(task.deadline)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: widget.strings.get('deleteTask'),
                                    onPressed: () =>
                                        widget.onDeleteTask(originalIndex),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    color: const Color(0xFFD25140),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.completedLabel,
    required this.pendingLabel,
    required this.overdueLabel,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final String completedLabel;
  final String pendingLabel;
  final String overdueLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? <Color>[const Color(0xFF21473B), const Color(0xFF153028)]
              : <Color>[const Color(0xFF1E3F36), const Color(0xFF2D6D5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _StatChip(value: '$completedCount', label: completedLabel),
              _StatChip(value: '$pendingCount', label: pendingLabel),
              _StatChip(value: '$overdueCount', label: overdueLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.edit_calendar_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
