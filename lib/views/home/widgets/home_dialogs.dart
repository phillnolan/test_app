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
  const SyncCredentialsDialog({
    super.key,
    this.initialUsername,
    this.initialPassword,
  });

  final String? initialUsername;
  final String? initialPassword;

  @override
  State<SyncCredentialsDialog> createState() => _SyncCredentialsDialogState();
}

class _SyncCredentialsDialogState extends State<SyncCredentialsDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialUsername ?? '';
    _passwordController.text = widget.initialPassword ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return _CredentialActionSheet(
      icon: Icons.sync_alt,
      title: 'Đồng bộ tài khoản sinh viên',
      subtitle:
          'Nhập tài khoản cổng trường để tải lịch học, lịch thi và bảng điểm mới nhất.',
      bottomInset: bottomInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(
            controller: _usernameController,
            labelText: 'Tên đăng nhập sinh viên',
            hintText: 'Ví dụ: 22110xxx',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _passwordController,
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu cổng trường',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
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
          const SizedBox(height: 12),
          _SubmitHint(
            text:
                'Hệ thống sẽ kiểm tra liên kết tài khoản ứng dụng với sinh viên này trước khi đồng bộ.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.sync),
                  label: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      return;
    }

    final confirmed = await _confirmSubmit(
      title: 'Xác nhận đồng bộ?',
      content: 'Bạn sắp đồng bộ tài khoản sinh viên "$username". Tiếp tục chứ?',
      actionLabel: 'Đồng bộ',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop(CredentialsResult(username: username, password: password));
  }

  Future<bool?> _confirmSubmit({
    required String title,
    required String content,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
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
    final isSignIn = _mode == EmailAuthMode.signIn;

    return _CredentialActionSheet(
      icon: isSignIn ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
      title: isSignIn ? 'Đăng nhập bằng email' : 'Tạo tài khoản ứng dụng',
      subtitle: isSignIn
          ? 'Dùng email để mở dữ liệu cloud và liên kết với tài khoản sinh viên.'
          : 'Tạo tài khoản ứng dụng mới để lưu ghi chú, ảnh, tệp và dữ liệu đồng bộ.',
      bottomInset: bottomInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<EmailAuthMode>(
            segments: const [
              ButtonSegment(
                value: EmailAuthMode.signIn,
                icon: Icon(Icons.login_rounded),
                label: Text('Đăng nhập'),
              ),
              ButtonSegment(
                value: EmailAuthMode.register,
                icon: Icon(Icons.person_add_alt_1_rounded),
                label: Text('Đăng ký'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(height: 16),
          _SheetField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Nhập email của bạn',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _passwordController,
            labelText: 'Mật khẩu',
            hintText: isSignIn
                ? 'Nhập mật khẩu để đăng nhập'
                : 'Tạo mật khẩu cho tài khoản mới',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
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
          const SizedBox(height: 12),
          _SubmitHint(
            text: isSignIn
                ? 'Sau khi đăng nhập, app sẽ kiểm tra liên kết dữ liệu sinh viên hiện có.'
                : 'Sau khi tạo tài khoản, app có thể liên kết ngay với dữ liệu sinh viên đang có trên máy.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    isSignIn
                        ? Icons.login_rounded
                        : Icons.person_add_alt_1_rounded,
                  ),
                  label: Text(isSignIn ? 'Tiếp tục' : 'Tạo tài khoản'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    final isSignIn = _mode == EmailAuthMode.signIn;
    final confirmed = await _confirmSubmit(
      title: isSignIn ? 'Xác nhận đăng nhập?' : 'Xác nhận đăng ký?',
      content: isSignIn
          ? 'Bạn sắp đăng nhập bằng email "$email". Tiếp tục chứ?'
          : 'Bạn sắp tạo tài khoản mới với email "$email". Tiếp tục chứ?',
      actionLabel: isSignIn ? 'Đăng nhập' : 'Đăng ký',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop(EmailAuthResult(mode: _mode, email: email, password: password));
  }

  Future<bool?> _confirmSubmit({
    required String title,
    required String content,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _CredentialActionSheet extends StatelessWidget {
  const _CredentialActionSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bottomInset,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}

class _SubmitHint extends StatelessWidget {
  const _SubmitHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
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
