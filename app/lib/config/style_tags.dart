/// 온보딩 스타일 태그 어휘집. 백엔드 UserPreference.StyleTag와 반드시 동기화해야 한다
/// (service-policy.md §1, open-decisions.md A7, 2026-07-27 결정).
const List<String> kStyleTags = [
  '미니멀',
  '캐주얼',
  '스트릿',
  '러블리',
  '페미닌',
  '시크',
  '빈티지',
  '스포티',
  '클래식',
  '프레피',
  '유니크',
  '오피스룩',
];

/// 체형(골격) 타입 키워드. 스트레이트/웨이브/내추럴 3형 진단 체계를 따른다.
/// UserPreference.bodyInfo(자유 텍스트)에 "체형: {키워드} 타입" 형태로 합쳐 저장되며,
/// 추천 엔진 프롬프트의 [체형 정보] 섹션에서 그대로 재사용된다.
const List<String> kBodyTypeTags = ['스트레이트', '웨이브', '내추럴'];

/// 스타일 태그별 무드보드 사진(Unsplash, 임시 예시 이미지). 실제 룩북 촬영본이 생기면 교체한다.
const Map<String, String> kStyleTagImages = {
  '미니멀': 'https://images.unsplash.com/photo-1589713680561-1d0b6945a582?w=400&q=80&auto=format&fit=crop',
  '캐주얼': 'https://images.unsplash.com/photo-1619216910014-1fdb7a8e98e9?w=400&q=80&auto=format&fit=crop',
  '스트릿': 'https://images.unsplash.com/photo-1584216338898-f34d78201414?w=400&q=80&auto=format&fit=crop',
  '러블리': 'https://images.unsplash.com/photo-1761932995009-4003235581b4?w=400&q=80&auto=format&fit=crop',
  '페미닌': 'https://images.unsplash.com/photo-1646296142225-28436a93863a?w=400&q=80&auto=format&fit=crop',
  '시크': 'https://images.unsplash.com/photo-1584273143981-41c073dfe8f8?w=400&q=80&auto=format&fit=crop',
  '빈티지': 'https://images.unsplash.com/photo-1616750726675-6abbb55a2606?w=400&q=80&auto=format&fit=crop',
  '스포티': 'https://images.unsplash.com/photo-1618355281951-a174b87198e2?w=400&q=80&auto=format&fit=crop',
  '클래식': 'https://images.unsplash.com/photo-1779406275908-1dabe4083373?w=400&q=80&auto=format&fit=crop',
  '프레피': 'https://images.unsplash.com/photo-1762232979295-47b301ef9782?w=400&q=80&auto=format&fit=crop',
  '유니크': 'https://images.unsplash.com/photo-1779810677455-449ae4ee2bc7?w=400&q=80&auto=format&fit=crop',
  '오피스룩': 'https://images.unsplash.com/photo-1573496130141-209d200cebd8?w=400&q=80&auto=format&fit=crop',
};

