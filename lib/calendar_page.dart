import 'package:flutter/material.dart';

import 'models.dart';
import 'main.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.strings, required this.tasks});

  final AppStrings strings;
  final List<TaskItem> tasks;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _twoDigits(int number) => number.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  List<DateTime> _monthGridDays() {
    final DateTime firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final int weekday = firstDay.weekday; // 1=Mon..7=Sun
    final DateTime start = firstDay.subtract(Duration(days: weekday - 1));
    return List<DateTime>.generate(42, (int index) {
      return DateTime(start.year, start.month, start.day + index);
    });
  }

  int _taskCountForDay(DateTime day) {
    return widget.tasks
        .where((TaskItem task) => _isSameDay(task.deadline, day))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<DateTime> gridDays = _monthGridDays();
    final List<TaskItem> selectedTasks =
        widget.tasks
            .where((TaskItem task) => _isSameDay(task.deadline, _selectedDate))
            .toList()
          ..sort((TaskItem a, TaskItem b) => a.deadline.compareTo(b.deadline));

    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[
                      const Color(0xFF0F1F1A),
                      const Color(0xFF153229),
                      const Color(0xFF1B3A31),
                    ]
                  : <Color>[
                      const Color(0xFFE3F4EC),
                      const Color(0xFFF8F2E8),
                      const Color(0xFFF0FAF4),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -65,
          right: -40,
          child: _GlowOrb(
            size: 175,
            color: isDark
                ? const Color(0xFF7BDABC).withValues(alpha: 0.22)
                : const Color(0xFF89DFC4).withValues(alpha: 0.28),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? <Color>[
                              const Color(0xFF21473B),
                              const Color(0xFF153028),
                            ]
                          : <Color>[
                              const Color(0xFF1E3F36),
                              const Color(0xFF2D6D5D),
                            ],
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.strings.get('calendar'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month - 1,
                                  );
                                });
                              },
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Expanded(
                              child: Text(
                                '${_focusedMonth.month}/${_focusedMonth.year}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month + 1,
                                  );
                                });
                              },
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 42,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                          itemBuilder: (BuildContext context, int index) {
                            final DateTime day = gridDays[index];
                            final bool inMonth =
                                day.month == _focusedMonth.month;
                            final bool selected = _isSameDay(
                              day,
                              _selectedDate,
                            );
                            final int dayTaskCount = _taskCountForDay(day);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = day;
                                  _focusedMonth = DateTime(day.year, day.month);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : (inMonth
                                            ? Colors.white.withValues(
                                                alpha: isDark ? 0.08 : 0.72,
                                              )
                                            : Colors.white.withValues(
                                                alpha: isDark ? 0.03 : 0.34,
                                              )),
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    Center(
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? Colors.white
                                              : (inMonth
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.45,
                                                          )),
                                        ),
                                      ),
                                    ),
                                    if (dayTaskCount > 0)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? Colors.white.withValues(
                                                    alpha: 0.92,
                                                  )
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$dayTaskCount',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: selectedTasks.isEmpty
                      ? Center(
                          child: Text(
                            widget.strings.get('emptyTitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: selectedTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final TaskItem task = selectedTasks[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: task.isCompleted
                                      ? const Color(0xFF2AA06A)
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(task.title),
                                subtitle: Text(
                                  '${task.category} • ${widget.strings.get('dueLabel')}: ${_formatDateTime(task.deadline)}',
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
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 16),
          ],
        ),
      ),
    );
  }
}
