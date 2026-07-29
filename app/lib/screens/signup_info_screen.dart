import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../config/style_tags.dart';
import '../widgets/step_indicator.dart';
import '../widgets/trendfit_top_bar.dart';
import 'style_preference_screen.dart';

/// 회원정보 입력 (STEP 01). (Figma "회원정보 입력")
/// 백엔드 UserPreference에는 구조화된 이름/성별/나이/신장/체중 컬럼이 없고 자유 텍스트
/// bodyInfo만 있어서(open-decisions.md 범위 밖 스키마 변경 없이), 이 화면에서 모은 값은
/// 한 문장으로 합쳐 다음 화면(StylePreferenceScreen)의 체형 정보로 전달한다.
class SignupInfoScreen extends StatefulWidget {
  const SignupInfoScreen({super.key});

  @override
  State<SignupInfoScreen> createState() => _SignupInfoScreenState();
}

class _SignupInfoScreenState extends State<SignupInfoScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _gender;
  String? _bodyType;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _next() {
    final parts = <String>[];
    if (_gender != null) parts.add('성별: $_gender');
    if (_ageController.text.trim().isNotEmpty) parts.add('나이: ${_ageController.text.trim()}세');
    if (_heightController.text.trim().isNotEmpty) parts.add('키: ${_heightController.text.trim()}cm');
    if (_weightController.text.trim().isNotEmpty) parts.add('몸무게: ${_weightController.text.trim()}kg');
    if (_bodyType != null) parts.add('체형: $_bodyType 타입');
    final bodyInfo = parts.isEmpty ? null : parts.join(', ');

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StylePreferenceScreen(initialBodyInfo: bodyInfo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrendFitTopBar(onBack: () => Navigator.of(context).pop()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIndicator(step: 1, total: 2, label: '회원정보'),
              const SizedBox(height: 8),
              Text('당신을 위한 맞춤 핏을 위해\n정보를 입력해주세요', style: AppTextStyles.displayHeavy.copyWith(fontSize: 26))
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 40),
              _fieldLabel('이름'),
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: '홍길동')),
              const SizedBox(height: 32),
              _fieldLabel('성별'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _genderOption('남성')),
                  const SizedBox(width: 12),
                  Expanded(child: _genderOption('여성')),
                ],
              ),
              const SizedBox(height: 32),
              _numberField(label: '나이', controller: _ageController, suffix: '세'),
              const SizedBox(height: 24),
              _numberField(label: '신장', controller: _heightController, suffix: 'CM'),
              const SizedBox(height: 24),
              _numberField(label: '체중', controller: _weightController, suffix: 'KG'),
              const SizedBox(height: 32),
              _fieldLabel('체형 타입 (선택)'),
              const SizedBox(height: 4),
              Text(
                '골격 진단 결과를 아시면 선택해주세요. 추천 시 실루엣/핏 참고에 활용됩니다.',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < kBodyTypeTags.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _bodyTypeOption(kBodyTypeTags[i])),
                  ],
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _next, child: const Text('NEXT')),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '입력하신 정보는 스타일 추천 알고리즘에만 사용됩니다.',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) =>
      Text(text, style: AppTextStyles.trackedLabel.copyWith(color: AppColors.textPrimary));

  Widget _genderOption(String value) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.black : AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Text(
          value.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 1.4,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _bodyTypeOption(String value) {
    final selected = _bodyType == value;
    return InkWell(
      onTap: () => setState(() => _bodyType = selected ? null : value),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.black : AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 0.4,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _numberField({required String label, required TextEditingController controller, required String suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        // IntrinsicWidth를 쓰면 입력값 글자 수만큼만 필드 폭(=밑줄 길이)이 잡혀서 이름 필드보다
        // 훨씬 짧아 보였다 — 이름 필드처럼 처음부터 전체 폭을 차지하게 한다.
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: '  $suffix'),
        ),
      ],
    );
  }
}
