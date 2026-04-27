import 'package:flutter/material.dart';

import '../widgets/home_common_widgets.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        _QuizHeroCard(),
        SizedBox(height: 16),
        PlaceholderInfoCard(
          icon: Icons.quiz_outlined,
          title: 'Sẵn sàng cho ngân hàng câu hỏi',
          description:
              'Mục Quiz sẽ là nơi gom đề luyện tập, bộ câu hỏi theo môn và tiến độ ôn luyện cá nhân.',
        ),
        SizedBox(height: 12),
        PlaceholderInfoCard(
          icon: Icons.auto_stories_outlined,
          title: 'Gợi ý triển khai tiếp',
          description:
              'Có thể mở rộng bằng quiz theo môn, flashcard, lịch sử làm bài và đồng bộ kết quả lên cloud.',
        ),
      ],
    );
  }
}

class _QuizHeroCard extends StatelessWidget {
  const _QuizHeroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ô luyện nhanh bằng các bộ câu hỏi ngắn, bám sát từng môn học.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.86),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
