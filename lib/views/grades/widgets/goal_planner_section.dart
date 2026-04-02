import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../controllers/grades_controller.dart';
import '../../../models/program_subject.dart';
import '../../../utils/grade_metrics.dart';

class GoalPlannerSection extends StatefulWidget {
  const GoalPlannerSection({super.key, required this.controller});

  final GradesController controller;

  @override
  State<GoalPlannerSection> createState() => _GoalPlannerSectionState();
}

class _GoalPlannerSectionState extends State<GoalPlannerSection> {
  late final TextEditingController _targetGpaController = TextEditingController(
    text: widget.controller.targetGpaInput,
  );

  @override
  void didUpdateWidget(covariant GoalPlannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _targetGpaController.text = widget.controller.targetGpaInput;
  }

  @override
  void dispose() {
    _targetGpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = widget.controller.goalPlanDefaults;
    final calculation = widget.controller.goalPlanCalculation;
    final result = calculation.result;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Muc tieu',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetGpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: widget.controller.setTargetGpaInput,
            decoration: InputDecoration(
              labelText: 'GPA muc tieu he 4',
              hintText: 'Vi du: 3.20',
              errorText: calculation.validationError,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: defaults.selectableFutureSubjects.isEmpty
                ? null
                : () => _openGuaranteedASelector(defaults),
            icon: const Icon(Icons.checklist_rtl_outlined),
            label: Text(
              widget.controller.guaranteedASubjectCodes.isEmpty
                  ? 'Chon cac mon chac A'
                  : 'Chinh danh sach chac A (${widget.controller.guaranteedASubjectCodes.length})',
            ),
          ),
          const SizedBox(height: 12),
          if (result == null)
            Text(
              'Nhap GPA muc tieu de xem lo trinh.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            _GoalSummaryCard(result: result),
            const SizedBox(height: 12),
            _GoalRecommendationTile(
              title: 'Hoc phan con lai',
              subtitle:
                  'Giu quanh ${result.remainingBand.label4} (${result.remainingBand.letter}).',
            ),
            if (result.retakeSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Nen hoc lai toi thieu',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Column(
                children: result.retakeSuggestions
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RetakeSuggestionCard(item: item),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (result.includeGraduationProject) ...[
              const SizedBox(height: 10),
              _GoalRecommendationTile(
                title: result.thesisLabel,
                subtitle:
                    'Giu toi thieu ${result.thesisBand.label4} (${result.thesisBand.letter}).',
              ),
            ],
            const SizedBox(height: 12),
            Text(
              result.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGuaranteedASelector(GoalPlanDefaults defaults) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _GuaranteedASelectorDialog(
        subjects: defaults.selectableFutureSubjects,
        initialSelection: widget.controller.guaranteedASubjectCodes,
        completedElectiveCount: defaults.completedElectiveCount,
        requiredElectiveCount: defaults.requiredElectiveCount,
      ),
    );
    if (result == null) return;
    widget.controller.setGuaranteedASubjectCodes(result);
  }
}

class _GuaranteedASelectorDialog extends StatefulWidget {
  const _GuaranteedASelectorDialog({
    required this.subjects,
    required this.initialSelection,
    required this.completedElectiveCount,
    required this.requiredElectiveCount,
  });

  final List<ProgramSubject> subjects;
  final Set<String> initialSelection;
  final int completedElectiveCount;
  final int requiredElectiveCount;

  @override
  State<_GuaranteedASelectorDialog> createState() =>
      _GuaranteedASelectorDialogState();
}

class _GuaranteedASelectorDialogState
    extends State<_GuaranteedASelectorDialog> {
  late final Set<String> _selectedCodes;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedCodes = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final coreSubjects = widget.subjects
        .where((item) => !item.isElective)
        .toList();
    final electiveSubjects = widget.subjects
        .where((item) => item.isElective)
        .toList();
    final electiveSelectedCount = electiveSubjects
        .where((item) => _selectedCodes.contains(item.subjectCode))
        .length;
    final maxElectiveSelection = math.max(
      0,
      widget.requiredElectiveCount - widget.completedElectiveCount,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chon cac mon chac A',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tu chon con duoc chon $maxElectiveSelection mon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectorSection(
                        title: 'Bat buoc',
                        subjects: coreSubjects,
                        selectedCodes: _selectedCodes,
                        onToggle: _toggle,
                      ),
                      if (electiveSubjects.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SelectorSection(
                          title: 'Tu chon',
                          subjects: electiveSubjects,
                          selectedCodes: _selectedCodes,
                          onToggle: (subject) {
                            final alreadySelected = _selectedCodes.contains(
                              subject.subjectCode,
                            );
                            if (!alreadySelected &&
                                electiveSelectedCount >= maxElectiveSelection) {
                              setState(() {
                                _errorText =
                                    'Ban chi co the chon toi da $maxElectiveSelection mon tu chon.';
                              });
                              return;
                            }
                            _toggle(subject);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selectedCodes),
                  child: const Text('Luu chon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(ProgramSubject subject) {
    setState(() {
      _errorText = null;
      if (_selectedCodes.contains(subject.subjectCode)) {
        _selectedCodes.remove(subject.subjectCode);
      } else {
        _selectedCodes.add(subject.subjectCode);
      }
    });
  }
}

class _SelectorSection extends StatelessWidget {
  const _SelectorSection({
    required this.title,
    required this.subjects,
    required this.selectedCodes,
    required this.onToggle,
  });

  final String title;
  final List<ProgramSubject> subjects;
  final Set<String> selectedCodes;
  final ValueChanged<ProgramSubject> onToggle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = screenWidth < 520 ? double.infinity : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: subjects
              .map(
                (subject) => SizedBox(
                  width: itemWidth,
                  child: _SelectableSubjectCard(
                    subject: subject,
                    selected: selectedCodes.contains(subject.subjectCode),
                    onTap: () => onToggle(subject),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SelectableSubjectCard extends StatelessWidget {
  const _SelectableSubjectCard({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final ProgramSubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.9)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.subjectName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.credits} tin chi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({required this.result});

  final GoalPlanResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GoalMetric(
              label: 'Muc tieu',
              value: result.targetGpa.toStringAsFixed(2),
            ),
          ),
          Expanded(
            child: _GoalMetric(
              label: 'Con lai',
              value: '${result.remainingCredits} tin',
            ),
          ),
          Expanded(
            child: _GoalMetric(
              label: 'Hoc lai',
              value: '${result.retakeSuggestions.length} mon',
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _GoalRecommendationTile extends StatelessWidget {
  const _GoalRecommendationTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RetakeSuggestionCard extends StatelessWidget {
  const _RetakeSuggestionCard({required this.item});

  final RetakeSuggestion item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.grade.subjectName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ban dau: ${item.grade.letter}  •  Can: ${item.targetLetter}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
