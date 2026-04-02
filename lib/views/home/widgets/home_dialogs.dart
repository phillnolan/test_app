import 'package:flutter/material.dart';

import '../../../controllers/home_flow_models.dart';

enum CalendarEventLevel { none, normal, important }

class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.eventLevelForDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final CalendarEventLevel Function(DateTime date) eventLevelForDate;

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final firstAllowedMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );
    final lastAllowedMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leadingEmptyCount = firstOfMonth.weekday - 1;
    final totalCells = leadingEmptyCount + daysInMonth;
    final canGoPrevious = _displayedMonth.isAfter(firstAllowedMonth);
    final canGoNext = _displayedMonth.isBefore(lastAllowedMonth);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _monthLabel(_displayedMonth),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: canGoPrevious ? _goToPreviousMonth : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: canGoNext ? _goToNextMonth : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _WeekdayCell(label: 'T2'),
                _WeekdayCell(label: 'T3'),
                _WeekdayCell(label: 'T4'),
                _WeekdayCell(label: 'T5'),
                _WeekdayCell(label: 'T6'),
                _WeekdayCell(label: 'T7'),
                _WeekdayCell(label: 'CN'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyCount) {
                  return const SizedBox.shrink();
                }

                final day = index - leadingEmptyCount + 1;
                final date = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month,
                  day,
                );
                final isSelected = DateUtils.isSameDay(
                  date,
                  widget.initialDate,
                );
                final isOutOfRange =
                    date.isBefore(
                      DateTime(
                        widget.firstDate.year,
                        widget.firstDate.month,
                        widget.firstDate.day,
                      ),
                    ) ||
                    date.isAfter(
                      DateTime(
                        widget.lastDate.year,
                        widget.lastDate.month,
                        widget.lastDate.day,
                      ),
                    );

                return _MonthDayCell(
                  date: date,
                  isSelected: isSelected,
                  isDisabled: isOutOfRange,
                  eventLevel: widget.eventLevelForDate(date),
                  onTap: isOutOfRange
                      ? null
                      : () => Navigator.of(context).pop(date),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  String _monthLabel(DateTime date) {
    return 'Tháng ${date.month}/${date.year}';
  }
}

class SyncCredentialsDialog extends StatefulWidget {
  const SyncCredentialsDialog({super.key});

  @override
  State<SyncCredentialsDialog> createState() => _SyncCredentialsDialogState();
}

class _SyncCredentialsDialogState extends State<SyncCredentialsDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đăng nhập để đồng bộ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Tên đăng nhập',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final username = _usernameController.text.trim();
            final password = _passwordController.text;
            if (username.isEmpty || password.isEmpty) {
              return;
            }

            Navigator.of(
              context,
            ).pop(CredentialsResult(username: username, password: password));
          },
          child: const Text('Đồng bộ'),
        ),
      ],
    );
  }
}

class EmailAuthSheet extends StatefulWidget {
  const EmailAuthSheet({super.key});

  @override
  State<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<EmailAuthSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  EmailAuthMode _mode = EmailAuthMode.signIn;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mode == EmailAuthMode.signIn ? 'Đăng nhập email' : 'Tạo tài khoản',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<EmailAuthMode>(
            segments: const [
              ButtonSegment(
                value: EmailAuthMode.signIn,
                label: Text('Đăng nhập'),
              ),
              ButtonSegment(
                value: EmailAuthMode.register,
                label: Text('Đăng ký'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                if (email.isEmpty || password.isEmpty) {
                  return;
                }

                Navigator.of(context).pop(
                  EmailAuthResult(
                    mode: _mode,
                    email: email,
                    password: password,
                  ),
                );
              },
              child: Text(
                _mode == EmailAuthMode.signIn ? 'Đăng nhập' : 'Tạo tài khoản',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayCell extends StatelessWidget {
  const _WeekdayCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.isSelected,
    required this.isDisabled,
    required this.eventLevel,
    this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isDisabled;
  final CalendarEventLevel eventLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.28)
        : isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final background = isSelected ? colorScheme.primaryContainer : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: foreground,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            _MonthEventDot(level: eventLevel),
          ],
        ),
      ),
    );
  }
}

class _MonthEventDot extends StatelessWidget {
  const _MonthEventDot({required this.level});

  final CalendarEventLevel level;

  @override
  Widget build(BuildContext context) {
    if (level == CalendarEventLevel.none) {
      return const SizedBox(height: 6);
    }

    final color = switch (level) {
      CalendarEventLevel.important => const Color(0xFFC62828),
      CalendarEventLevel.normal => const Color(0xFF9AA0A6),
      CalendarEventLevel.none => Colors.transparent,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
