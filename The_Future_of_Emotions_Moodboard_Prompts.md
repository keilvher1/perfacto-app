# 🎬 The Future of Emotions — 무드보드 & 이미지 생성 프롬프트 가이드

> **프로젝트**: "The Future of Emotions" SF 단편영화
> **배경**: 2036년 미래 대학교
> **장르**: SF Drama
> **목표**: 영화제 출품용 무드보드 이미지 생성
> **도구**: Midjourney, Gemini, Higgsfield, Kling, ChatGPT Pro

---

## 1. 레퍼런스 스타일 분석 (폴 심 캐릭터 이미지 기반)

### 1-1. 아트 스타일 키워드
- **일러스트레이션 스타일**: 세미 리얼리스틱, 페인팅/디지털 페인팅 질감
- **터치**: 깨끗한 라인 + 부드러운 텍스처 브러시워크, 약간의 스케치 느낌
- **톤**: 따뜻하고 차분한, 약간 멜랑콜리한 분위기
- **디테일 수준**: 중간~높음 (인물은 정교, 배경은 약간 추상적)

### 1-2. 컬러 팔레트
| 요소 | 컬러 | HEX 참고 |
|------|-------|----------|
| 피부톤 | 따뜻한 올리브/베이지 | #C4A882 |
| 카디건/의상 | 베이지/크림 | #D4C5A9 |
| 배경 따뜻한 톤 | 세피아/아이보리 | #F0E6D3 |
| 악센트 (따뜻) | 머스타드/번트 오렌지 | #C8923C |
| 악센트 (차가운) | 올리브 그린 | #6B7F5E |
| 그림자 | 웜 브라운 | #5A4A3A |
| AI 공간 색상 | 틸/사이안 | #2A8B8B |
| AI 하이라이트 | 크롬/실버 | #C0C0C0 |

### 1-3. Midjourney 공통 스타일 서픽스
```
--style raw --ar 16:9 --v 6.1 --s 250
```

### 1-4. 공통 스타일 프리픽스 (모든 프롬프트에 적용)
```
warm digital illustration style, semi-realistic painterly aesthetic,
soft textured brushwork, muted earth tones palette with beige and
sepia undertones, subtle melancholic atmosphere, cinematic composition,
film grain texture overlay, 2036 near-future setting --style raw
```

---

## 2. 색감 대비 시스템 (영화 전체 비주얼 톤)

이 영화의 핵심 비주얼 전략은 **두 세계의 색감 대비**입니다:

| 구분 | 폴의 세계 (인간) | AI의 세계 |
|------|------------------|-----------|
| 색온도 | 3200K (따뜻) | 6000K (차가운) |
| 주요색 | Sepia, Beige, Amber | Teal, Chrome, White |
| 질감 | 아날로그, 거칠고 불완전 | 매끄럽고 완벽한 |
| 조명 | 자연광, 텅스텐 | 형광등, LED, 홀로그램 |
| 카메라 | 핸드헬드 (살짝 흔들림) | 스테디캠 (완벽 안정) |

---

## 3. 환경/배경 이미지 프롬프트 (전경 — 넓고, 사람 없음)

### 3-1. 🏛️ EXT. 미래 대학교 캠퍼스 — 새벽 (에스타블리싱 샷)

**씬 참조**: Scene 1 — 새벽의 대학교 외관 전경

**Midjourney 프롬프트**:
```
vast wide establishing shot of a futuristic university campus at dawn,
year 2036, no people, empty grounds, sleek chrome and glass architecture
mixed with minimal concrete, holographic university signs floating in
mid-air displaying "Department of Emotional Optimization", teal LED
accent lighting on building edges, morning mist rolling across a
perfectly manicured geometric lawn, cherry blossom trees with subtle
bioluminescent glow, the sky gradient from deep navy to pale amber,
warm digital illustration style, semi-realistic painterly aesthetic,
soft textured brushwork, muted earth tones meeting cold teal tones,
cinematic composition, film grain texture overlay, ultra-wide angle
lens perspective, atmospheric depth --style raw --ar 21:9 --v 6.1 --s 350
```

**Gemini 프롬프트 (텍스트)**:
```
2036년 미래 대학교 캠퍼스의 새벽 전경. 초광각 렌즈로 촬영한 듯한 구도.
사람은 전혀 없고, 크롬과 유리로 된 미래적 건축물들이 안개 속에 서 있다.
건물 외벽에는 틸색 LED 조명이 은은하게 빛나고, 공중에 홀로그램 간판이
"감정 최적화학과"라고 떠 있다. 기하학적으로 정돈된 잔디밭 위로 아침
안개가 깔려 있다. 컬러 팔레트는 베이지/세피아 배경에 틸/크롬 악센트.
디지털 일러스트레이션 스타일, 세미 리얼리스틱, 영화적 구도.
```

**Higgsfield 다듬기 참고**:
- 안개 움직임 추가
- 홀로그램 간판 미세한 글리치 효과
- 전경에 떨어지는 벚꽃잎 애니메이션

---

### 3-2. 🏛️ EXT. 대학교 캠퍼스 — 주간 (Scene 5 기반)

**씬 참조**: Scene 5 — 캠퍼스 정경, 모든 것이 최적화된 풍경

**Midjourney 프롬프트**:
```
ultra-wide panoramic view of a perfectly optimized futuristic university
campus in broad daylight, 2036, completely empty with no people,
symmetric pathways made of luminous white stone, drone delivery pods
hovering in formation above, transparent glass walkways connecting
buildings at second floor level, digital information boards showing
"Emotion Index: 94.7% Optimized" in teal holographic text, sterile
and pristine environment, everything geometrically perfect, a single
old wooden bench sits abandoned in the corner looking out of place,
warm digital illustration style, semi-realistic painterly brushwork,
the contrast between cold perfection and warm imperfection, muted
teal-chrome palette with one warm sepia accent area, cinematic wide
shot, atmospheric haze, subtle lens flare from artificial sun panels
--style raw --ar 21:9 --v 6.1 --s 300
```

**Higgsfield 다듬기 참고**:
- 드론 배달 포드 느린 이동
- 홀로그램 텍스트 부드러운 갱신 애니메이션
- 미세한 바람에 의한 나뭇잎 흔들림

---

### 3-3. 🚶 INT. AI 최적화 복도 — 차가운 톤 (Scene 2–3 기반)

**씬 참조**: Scene 2 — 인간이 없는 복도, AI가 관리하는 공간

**Midjourney 프롬프트**:
```
long perspective view of an empty futuristic university corridor,
2036, no people at all, walls made of smooth white panels with
embedded teal LED strips running along the edges, floor is polished
chrome reflecting the ceiling lights, holographic class schedules
float at eye level along the walls showing "AI Ethics 301 - Cancelled"
and "Emotional Calibration Lab - Full", ceiling has a continuous strip
of cool white 6000K lighting, one side of the corridor has floor-to-ceiling
windows showing the campus outside, the other has sealed classroom
doors with biometric scanners, sterile and clinical atmosphere,
everything is perfectly symmetrical, warm digital illustration style
but with deliberately cold color palette, semi-realistic painterly
aesthetic with soft textured brushwork, one-point perspective
vanishing point, cinematic composition, film grain overlay
--style raw --ar 21:9 --v 6.1 --s 300
```

---

### 3-4. 📚 INT. 폴 심의 강의실 — 따뜻한 톤 (핵심 장소)

**씬 참조**: Scene 6–11 — 마지막 수업이 열리는 강의실

**Midjourney 프롬프트**:
```
interior of a warm analog university classroom in a futuristic world,
2036, empty room with no people, old wooden lecture podium at the front,
real physical chalkboard with handwritten philosophy notes in chalk
reading fragments like "What is real emotion?" and "Pain = Meaning?",
scattered old hardcover books on the desk, a worn leather briefcase,
warm tungsten lighting 3200K casting golden glow, dust particles
floating in light beams from tall arched windows, wooden floor with
visible grain and wear marks, contrast with one wall that has a dormant
holographic display screen showing "SYSTEM: This classroom scheduled
for decommission", vintage desk lamps with warm amber bulbs, sepia and
beige color palette with amber and burnt orange accents, warm digital
illustration style, semi-realistic painterly aesthetic, soft textured
brushwork, intimate and melancholic atmosphere, wide-angle interior shot,
the warmth of this space contrasts with the cold world outside
--style raw --ar 16:9 --v 6.1 --s 350
```

**Higgsfield 다듬기 참고**:
- 먼지 입자 부유 애니메이션
- 창문 통한 자연광 미세 변화
- 홀로그램 디스플레이 간헐적 글리치

---

### 3-5. 📚 INT. 폴의 개인 연구실/사무실

**씬 참조**: Scene 4 — 폴이 마지막 수업을 준비하는 공간

**Midjourney 프롬프트**:
```
cozy cluttered professor office in a futuristic university, 2036,
empty room no people, overflowing bookshelves with real physical books
and papers, an old wooden desk covered with handwritten notes and open
philosophy texts, a vintage desk lamp casting warm amber pool of light,
a framed photo of younger Paul with students on the desk, an old coffee
mug with "Philosophy Dept" text, walls covered with pinned papers and
post-it notes with philosophical quotes, one small window showing the
cold teal campus outside creating color contrast, a disconnected
holographic terminal gathering dust in the corner, warm 3200K lighting
throughout, sepia beige and brown color palette with amber highlights,
warm digital illustration style matching the reference character art,
semi-realistic painterly aesthetic, soft textured brushwork, intimate
cluttered warmth, medium wide shot, nostalgic and melancholic atmosphere,
every object tells a story of resistance against digital optimization
--style raw --ar 16:9 --v 6.1 --s 350
```

---

### 3-6. 🏛️ INT. 대학교 대강당 — 미래적 (Scene 14–15 기반)

**씬 참조**: Scene 14 — 에필로그, 빈 강의실에 울려퍼지는 여운

**Midjourney 프롬프트**:
```
vast empty futuristic university lecture hall, 2036, no people,
hundreds of sleek chrome and white seats arranged in a amphitheater
formation, each seat has a small holographic display dock embedded in
the armrest, the main stage has a massive curved holographic screen
currently displaying a blue standby pattern, cool teal ambient
lighting from ceiling panels, but one single warm spotlight remains
on at the wooden podium where a real microphone stands alone, the
contrast between the cold technological space and this one warm light
is the visual focus, abandoned feeling, echo of something meaningful
that just happened, warm digital illustration style, semi-realistic
painterly aesthetic, soft textured brushwork, dramatic lighting contrast,
cinematic composition with rule of thirds, wide establishing interior
shot, film grain overlay, melancholic but hopeful atmosphere
--style raw --ar 21:9 --v 6.1 --s 300
```

---

### 3-7. 🌆 EXT. 캠퍼스 옥상/테라스 — 석양 (Scene 15–16 기반)

**씬 참조**: Scene 15–16 — 폴이 떠나는 장면의 배경

**Midjourney 프롬프트**:
```
wide panoramic view from a futuristic university rooftop terrace at
sunset, 2036, completely empty no people, overlooking a vast cityscape
of chrome towers and floating holographic billboards, the sky is a
dramatic gradient from deep amber to soft lavender, the terrace itself
has clean geometric railings and a single old wooden chair facing the
view, scattered autumn leaves on the chrome floor creating warm-cold
contrast, in the distance a massive holographic sign reads "Emotion
Optimization Center" glowing teal against the warm sky, birds flying
in formation (or are they drones?), the atmosphere is bittersweet and
contemplative, warm digital illustration style, semi-realistic painterly
aesthetic, soft textured brushwork, golden hour lighting mixing with
artificial teal city lights, ultra-wide cinematic composition,
atmospheric depth and haze, film grain texture overlay
--style raw --ar 21:9 --v 6.1 --s 400
```

**Higgsfield 다듬기 참고**:
- 석양 빛 그라데이션 변화
- 멀리 도시 홀로그램 광고 미세한 움직임
- 나뭇잎 바람에 날리는 애니메이션
- 하늘의 새/드론 느린 이동

---

### 3-8. 🚶 INT. 엘리베이터/전환 공간 — AI 환경

**씬 참조**: Scene 3 — 폴이 AI 세계를 지나가는 전환 장면

**Midjourney 프롬프트**:
```
interior of a futuristic glass elevator moving through a transparent
shaft inside a university building, 2036, no people visible, the
elevator walls are transparent showing multiple floors of the building
as it descends, each floor visible through the glass shows different
AI-operated classrooms with holographic teachers lecturing to empty
seats, teal LED light strips line the elevator shaft, the elevator
panel shows floor indicators as floating holographic numbers, through
the glass you can see one floor that is darker and warmer — the
humanities floor — with old-fashioned wooden doors, warm digital
illustration style, semi-realistic painterly aesthetic, soft textured
brushwork, cool teal palette with one warm floor standing out,
vertical composition showing multiple levels, cinematic lighting,
film grain overlay --style raw --ar 9:16 --v 6.1 --s 300
```

---

## 4. 소품/디테일 클로즈업 이미지 프롬프트

### 4-1. 📖 칠판 클로즈업

**Midjourney 프롬프트**:
```
close-up of an old dusty green chalkboard in a futuristic classroom,
handwritten chalk text reading philosophical questions about emotion
and humanity, some text partially erased, chalk dust on the ledge,
warm amber lighting from the side, a small holographic "DECOMMISSION
NOTICE" sticker in the corner of the board frame, warm digital
illustration style, semi-realistic painterly aesthetic, rich textures,
sepia and green tones, intimate detail shot, shallow depth of field,
film grain --style raw --ar 16:9 --v 6.1 --s 250
```

---

### 4-2. 💡 감정칩 LED 클로즈업

**Midjourney 프롬프트**:
```
extreme close-up of a small LED chip embedded behind a human ear,
the chip has a hexagonal shape with microscopic circuits visible,
it glows with a steady teal light indicating "emotional calibration
active", the skin around it is slightly irritated showing the
foreign nature of the implant, warm skin tones contrasting with
cold teal technology light, warm digital illustration style,
semi-realistic painterly aesthetic, macro photography feel, shallow
depth of field, dramatic side lighting, film grain texture
--style raw --ar 16:9 --v 6.1 --s 250
```

---

### 4-3. 📓 폴의 가죽 브리프케이스와 노트

**Midjourney 프롬프트**:
```
still life of a worn brown leather briefcase sitting open on an old
wooden desk, inside are yellowed papers with handwritten notes, a
vintage fountain pen, reading glasses with thin gold frames, a
dog-eared copy of a philosophy book, warm tungsten lamp light
illuminating from above left, the desk surface has coffee ring stains
and scratch marks showing years of use, in the background blurred
holographic screen glows cold teal, warm digital illustration style,
semi-realistic painterly aesthetic, rich warm textures, intimate still
life composition, sepia and amber palette, film grain overlay
--style raw --ar 16:9 --v 6.1 --s 300
```

---

### 4-4. 🖥️ 홀로그램 학장 소피아 디스플레이

**Midjourney 프롬프트**:
```
a large curved holographic display screen in a futuristic office
showing the outline of an AI entity, the hologram has a feminine
silhouette made of flowing teal data streams and geometric patterns,
the display frame is sleek chrome, the office around it is cold and
minimal with white walls and no personal items, the hologram text
below reads "SOPHIA — Dean AI v.7.2", cold 6000K lighting, warm
digital illustration style but deliberately cold palette for this
scene, semi-realistic painterly aesthetic, the hologram has an
unsettling perfection to it, medium shot, cinematic composition,
film grain --style raw --ar 16:9 --v 6.1 --s 250
```

---

### 4-5. 🤖 하우스(AI 조교) 충전 스테이션

**Midjourney 프롬프트**:
```
a humanoid AI assistant standing in a charging station alcove in a
university hallway, no other people around, the AI has a smooth
androgynous face with subtle blue LED eyes, wearing a clean white
uniform with university logo, connected to the wall by a thin
translucent cable at the back of the neck, the charging alcove has
soft blue ambient light, a small status display reads "HAUS — Teaching
Assistant Unit 04 — Charging 87%", the corridor beyond is cold and
clinical, warm digital illustration style applied to cold subject
matter, semi-realistic painterly aesthetic, soft textured brushwork,
the uncanny valley feeling of an almost-human machine, medium full
shot, cool teal palette, film grain --style raw --ar 16:9 --v 6.1 --s 250
```

---

## 5. 캐릭터 이미지 프롬프트

### 5-1. 👤 폴 심 교수 — 추가 앵글/포즈

> **반드시 업로드한 레퍼런스 이미지를 --cref로 사용하세요**

**Midjourney 프롬프트 (뒷모습)**:
```
back view of a middle-aged Korean male professor walking alone down
a long futuristic university corridor, wearing a oversized beige
cardigan over a rumpled shirt, carrying an old leather briefcase,
his posture is slightly hunched with weariness, the corridor has
cold teal LED lighting but his figure radiates warmth through the
color of his clothes, he is small against the vast sterile architecture,
warm digital illustration style matching character reference,
semi-realistic painterly aesthetic, soft textured brushwork,
lonely atmospheric composition, cinematic long shot, the contrast
between human warmth and technological cold, film grain overlay
--style raw --ar 21:9 --v 6.1 --s 300 --cref [폴 심 레퍼런스 이미지 URL]
```

**Midjourney 프롬프트 (강의 중)**:
```
a middle-aged Korean male professor standing at an old wooden podium
in a warm-lit classroom, gesturing passionately while teaching,
wearing a beige cardigan with rolled up sleeves, chalk dust on his
hands, behind him a green chalkboard filled with handwritten notes,
warm 3200K tungsten lighting, dust particles in the air catching
golden light beams from tall windows, his expression is intense
and sincere, the classroom is mostly empty with only a few students
visible as blurred shapes, warm digital illustration style matching
character reference, semi-realistic painterly aesthetic, medium shot
slightly low angle to give him presence, sepia and amber palette,
film grain --style raw --ar 16:9 --v 6.1 --s 350 --cref [폴 심 레퍼런스 이미지 URL]
```

---

### 5-2. 👤 민규 — 감정칩 학생

**Midjourney 프롬프트**:
```
young Korean male university student age 21 sitting in a futuristic
classroom seat, short neat hair, wearing a clean minimal white and
grey outfit typical of 2036 fashion, a small teal LED glows steadily
behind his right ear indicating his emotion optimization chip is active,
his expression is controlled and neutral — almost too perfect, he sits
with perfect posture among empty seats, one hand rests on a holographic
tablet, but his eyes have a flicker of something unprocessed — doubt
or curiosity, warm digital illustration style, semi-realistic painterly
aesthetic, cool palette for his world but warm undertones in his skin,
medium close-up, cinematic portrait composition, film grain
--style raw --ar 16:9 --v 6.1 --s 300
```

**Midjourney 프롬프트 (클라이맥스 — 눈물)**:
```
close-up portrait of a young Korean male student with tears streaming
down his face, his emotion chip LED behind his ear is flickering and
sparking with small electrical arcs — it is malfunctioning, his
expression is raw and uncontrolled for the first time — genuine pain
mixed with wonder, the tears reflect warm amber light from the classroom
while the sparking chip casts erratic teal flashes, this is the moment
where real emotion breaks through technology, warm digital illustration
style, semi-realistic painterly aesthetic, extreme close-up, dramatic
mixed warm-cold lighting, shallow depth of field, emotionally intense,
the most important visual moment of the film, film grain overlay
--style raw --ar 16:9 --v 6.1 --s 400
```

---

### 5-3. 🤖 하우스 — 피지컬 AI 조교

**Midjourney 프롬프트**:
```
a humanoid AI teaching assistant standing at the back of a warm
university classroom, androgynous appearance with smooth perfect skin
and subtle blue-white LED eyes, wearing a crisp white university
uniform, standing perfectly still with hands clasped, watching the
human professor teach with an expression that could be curiosity or
simply data processing — deliberately ambiguous, the warm golden
light of the classroom softens the AI's clinical appearance slightly,
warm digital illustration style, semi-realistic painterly aesthetic,
full body shot from medium distance, the visual tension between
organic warmth and synthetic precision, cool character in warm
environment, film grain --style raw --ar 16:9 --v 6.1 --s 300
```

---

### 5-4. 💻 소피아 — 홀로그램 학장 AI

**Midjourney 프롬프트**:
```
a large holographic projection of a female AI entity in a sleek
futuristic office, the hologram is made of flowing teal and white
data particles forming a beautiful but uncanny feminine face and
upper body, the face has perfect symmetry and calm expression,
geometric patterns flow through the holographic body like digital
blood vessels, the projection hovers above a chrome desk, the
office behind is pristine white with no personal items, cold 6000K
lighting, the hologram casts a faint teal glow on surrounding
surfaces, warm digital illustration style applied to depict cold
perfection, semi-realistic painterly aesthetic, medium shot, the
beauty of the hologram is unsettling in its perfection, cinematic
composition, film grain --style raw --ar 16:9 --v 6.1 --s 300
```

---

## 6. 핵심 씬별 컴포지션 프롬프트 (키프레임)

### 6-1. 🎬 Scene 1 — 오프닝 에스타블리싱 샷
```
extreme wide shot of a futuristic university campus at dawn, 2036,
empty and quiet, mist rolling across chrome buildings, a single warm
light glows from one window on the humanities floor — Paul's office,
everything else is cold teal and dark, warm digital illustration style,
ultra cinematic, --ar 21:9 --v 6.1 --s 400 --style raw
```

### 6-2. 🎬 Scene 6 — 폴이 강의실 문을 여는 순간
```
point of view shot from inside a dark futuristic corridor looking
through a doorway into a warmly lit old-fashioned classroom, the
doorframe creates a strong visual boundary between two worlds —
cold teal corridor on the viewer's side and warm amber classroom
beyond, golden light spills into the dark corridor, chalk dust
visible in the warm light beams, an old wooden podium visible
through the door, warm digital illustration style, dramatic
lighting contrast, cinematic threshold composition, the visual
metaphor of crossing between two eras, --ar 16:9 --v 6.1 --s 350 --style raw
```

### 6-3. 🎬 Scene 11 — 민규의 눈물 (클라이맥스)
```
medium close-up two-shot, a young Korean student crying with his
emotion chip sparking teal behind his ear, sitting across from a
middle-aged professor who reaches out with a chalk-dusted hand,
the lighting is split — warm amber from the classroom windows
on the professor's side, erratic teal flashes from the malfunctioning
chip on the student's side, this is the moment technology fails
and humanity breaks through, emotional intensity, warm digital
illustration style, semi-realistic painterly aesthetic, dramatic
chiaroscuro, the most visually striking frame of the entire film,
--ar 16:9 --v 6.1 --s 450 --style raw
```

### 6-4. 🎬 Scene 14 — 빈 강의실 엔딩
```
wide shot of the now-empty warm classroom, the chalkboard still has
Paul's final notes, a single piece of chalk sits on the ledge, the
warm lamp is still on casting golden light on the empty podium,
through the window the cold teal campus is visible outside, the
chair where Minkyu sat has been pushed back slightly — evidence
of someone who left in emotional haste, warm digital illustration
style, painterly aesthetic, melancholic but beautiful, the visual
poem of absence and presence, --ar 16:9 --v 6.1 --s 400 --style raw
```

### 6-5. 🎬 Scene 16 — 포스트크레딧 (하우스의 미소)
```
extreme close-up of an AI humanoid face in a dim corridor, the
face is smooth and perfect with blue-white LED eyes, but one corner
of the mouth has the slightest upturn — the ghost of a smile, is
it mimicry or something more? the lighting is mostly cold teal but
a faint warm reflection from the classroom behind creates an amber
highlight on one cheek, warm digital illustration style, intimate
and mysterious, the ambiguity is the point, shallow depth of field,
--ar 16:9 --v 6.1 --s 350 --style raw
```

---

## 7. Kling 비디오 생성 프롬프트

### 7-1. 캠퍼스 새벽 — 슬로우 팬

**Kling 프롬프트**:
```
Slow cinematic pan across a misty futuristic university campus at
dawn, chrome buildings with teal LED accents, holographic signs
floating, no people, one warm light in a window, warm painterly
illustration style, atmospheric, 2036 setting
```

### 7-2. 복도 워킹 — 원포인트 퍼스펙티브

**Kling 프롬프트**:
```
Slow dolly forward through an empty futuristic university corridor,
white walls with teal LED strips, holographic schedules floating,
polished chrome floor, one-point perspective, cold clinical atmosphere,
warm painterly illustration style
```

### 7-3. 강의실 — 먼지 입자 플로팅

**Kling 프롬프트**:
```
Static wide shot of a warm old-fashioned classroom with golden
tungsten lighting, dust particles floating in light beams from
tall windows, chalkboard with handwritten notes, old wooden podium,
warm cozy atmosphere contrasting with futuristic world outside,
painterly illustration style
```

### 7-4. 민규 눈물 — 칩 스파크

**Kling 프롬프트**:
```
Close-up of a young man's face with tears, a small LED chip behind
his ear sparking and flickering with electrical arcs, mixed warm
amber and cold teal lighting, raw emotional expression, semi-realistic
painterly style, dramatic and intense
```

---

## 8. Higgsfield 이미지 다듬기 가이드

Higgsfield는 생성된 정지 이미지를 다듬고 미세 조정하는 데 사용합니다.

### 8-1. 전경 이미지 다듬기 체크리스트
- [ ] **사람 제거**: 전경에 생성된 사람 실루엣이나 인물 완전 제거
- [ ] **넓이 확장**: 이미지 좌우 확장 (outpainting) 으로 더 파노라믹하게
- [ ] **디테일 추가**: 홀로그램 텍스트, LED 조명 라인 등 SF 디테일 보강
- [ ] **색감 통일**: 레퍼런스 이미지의 따뜻한 토노 팔레트에 맞게 색보정
- [ ] **질감 추가**: 필름 그레인, 브러시 텍스처 오버레이

### 8-2. 캐릭터 이미지 다듬기 체크리스트
- [ ] **일관성 확보**: 폴 심 캐릭터의 얼굴/체형이 레퍼런스와 일치하는지 확인
- [ ] **의상 디테일**: 베이지 카디건, 구겨진 셔츠, 가죽 브리프케이스 디테일
- [ ] **감정칩 LED**: 민규의 귀 뒤 LED 일관된 위치와 색상
- [ ] **표정 미세 조정**: 특히 클라이맥스 씬의 감정 표현 강화

### 8-3. Higgsfield 프롬프트 패턴
```
Refine this image: [설명].
Adjustments needed:
- Remove any human figures from the background
- Extend the image wider to the left and right for panoramic feel
- Enhance the warm amber lighting on the left side
- Add subtle film grain texture
- Ensure the teal LED accents are consistent with #2A8B8B
- Maintain the semi-realistic painterly illustration style
```

---

## 9. ChatGPT Pro 활용 가이드

ChatGPT Pro는 다음 용도로 활용합니다:

### 9-1. DALL-E 이미지 생성
- Midjourney에서 원하는 결과가 안 나올 때 대안으로 사용
- 특히 **텍스트가 포함된 이미지** (간판, 칠판 글씨 등)는 DALL-E가 더 정확
- 프롬프트는 위의 Midjourney 프롬프트에서 `--style raw --ar 16:9 --v 6.1 --s 300` 등 MJ 전용 파라미터를 제거하고 사용

### 9-2. 스크립트/대사 다듬기
- 각 씬의 대사를 영화제용으로 세련되게 다듬기
- 영어 자막 번역 및 톤 조정
- 내레이션 텍스트 작성

### 9-3. 사운드 디자인 참조
- 각 씬의 사운드 무드를 텍스트로 설명하여 음악/효과음 방향 설정
- AI 생성 음악 프롬프트 작성 (Suno, Udio 등 활용 시)

---

## 10. 제작 워크플로우 요약

```
Step 1: Midjourney/Gemini → 초기 이미지 생성 (모든 환경 + 캐릭터)
Step 2: Higgsfield → 이미지 다듬기 (사람 제거, 확장, 디테일 보강)
Step 3: Kling → 정지 이미지 → 짧은 비디오 클립 변환
Step 4: ChatGPT Pro → 보조 이미지 생성 + 텍스트 콘텐츠
Step 5: 포스트 프로덕션 (편집, 색보정, 사운드)
```

---

## 11. 무드보드 구성 순서 (Notion 업로드용)

### 섹션 1: 컬러 팔레트 & 톤
- 따뜻한 팔레트 (폴의 세계) 스와치
- 차가운 팔레트 (AI 세계) 스와치
- 대비 예시 이미지

### 섹션 2: 환경/배경 — 전경
1. 캠퍼스 새벽 전경 (21:9)
2. 캠퍼스 주간 파노라마 (21:9)
3. 캠퍼스 석양 옥상 (21:9)

### 섹션 3: 환경/배경 — 실내
4. AI 복도 (차가운 톤)
5. 폴의 강의실 (따뜻한 톤)
6. 폴의 연구실 (따뜻한 톤)
7. 대강당 (혼합 톤)
8. 엘리베이터/전환 공간

### 섹션 4: 소품 디테일
9. 칠판 클로즈업
10. 감정칩 LED
11. 브리프케이스/노트
12. 소피아 홀로그램
13. 하우스 충전 스테이션

### 섹션 5: 캐릭터
14. 폴 심 — 다양한 앵글
15. 민규 — 일상/클라이맥스
16. 하우스 — AI 조교
17. 소피아 — 홀로그램

### 섹션 6: 키프레임 컴포지션
18. Scene 1 오프닝
19. Scene 6 문열림
20. Scene 11 클라이맥스
21. Scene 14 빈 강의실
22. Scene 16 하우스의 미소

---

*최종 업데이트: 2026.02.16*
*프로젝트: The Future of Emotions — SF 단편영화 무드보드*
