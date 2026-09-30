/// Bài ngữ pháp theo chủ đề: lý thuyết NGẮN (công thức, dấu hiệu, ví dụ
/// đúng/sai, bẫy hay gặp) + nút luyện ngay các câu cùng chủ đề trong ngân
/// hàng câu hỏi (lọc theo [practiceTopics] - đúng tên `topic` của câu hỏi).
library;

import 'package:mimi_pet/exam_engine/question_bank_models.dart';

class GrammarPoint {
  final String heading;
  final String formula;
  final String? note;

  const GrammarPoint(this.heading, this.formula, {this.note});
}

class GrammarExample {
  final String en;
  final String vi;

  /// false = câu SAI minh hoạ lỗi hay gặp (hiện kèm ❌).
  final bool correct;

  const GrammarExample(this.en, this.vi, {this.correct = true});
}

class GrammarLesson {
  final String id;
  final ExamTrack track;
  final String level;
  final String emoji;
  final String title;
  final String summary;
  final List<GrammarPoint> points;
  final List<String> signals;
  final List<GrammarExample> examples;
  final List<String> traps;
  final Skill practiceSkill;
  final int? practicePart;
  final List<String> practiceTopics;

  const GrammarLesson({
    required this.id,
    required this.track,
    required this.level,
    required this.emoji,
    required this.title,
    required this.summary,
    required this.points,
    this.signals = const [],
    required this.examples,
    this.traps = const [],
    required this.practiceSkill,
    this.practicePart,
    required this.practiceTopics,
  });

  bool matches(Question q) =>
      q.track == track &&
      q.level == level &&
      q.skill == practiceSkill &&
      (practicePart == null || q.partNumber == practicePart) &&
      practiceTopics.contains(q.topic);
}

class GrammarLessons {
  GrammarLessons._();

  static List<GrammarLesson> forLevel(ExamTrack track, String level) =>
      all.where((l) => l.track == track && l.level == level).toList();

  /// Bài ngữ pháp liên quan tới 1 câu hỏi (để hiện nút "Xem bài ngữ pháp"
  /// khi chữa bài) - null nếu câu đó không thuộc chủ đề ngữ pháp nào.
  static GrammarLesson? forQuestion(Question q) {
    for (final l in all) {
      if (l.matches(q)) return l;
    }
    return null;
  }

  static const _toeic = ExamTrack.toeic;
  static const _yle = ExamTrack.yle;

  static const all = <GrammarLesson>[
    // ================================================================ TOEIC
    GrammarLesson(
      id: 'toeic_word_form',
      track: _toeic,
      level: 'Standard',
      emoji: '🧩',
      title: 'Từ loại & vị trí trong câu',
      summary: 'Dạng chiếm nhiều câu nhất Part 5: nhìn VỊ TRÍ chỗ trống để chọn danh/động/tính/trạng từ.',
      points: [
        GrammarPoint('Danh từ (N)', 'a/an/the/my/his... + (adj) + ___ | giới từ + ___ | chủ ngữ đầu câu',
            note: 'Đuôi hay gặp: -tion, -ment, -ness, -ance/-ence, -ity, -er/-or (người), -ship'),
        GrammarPoint('Tính từ (Adj)', '___ + N | be/become/seem/remain + ___ | make/keep/find + O + ___',
            note: 'Đuôi hay gặp: -ive, -ful, -less, -able/-ible, -al, -ous, -ic, -ent/-ant'),
        GrammarPoint('Trạng từ (Adv)', 'bổ nghĩa động từ, tính từ, phân từ (V-ed), cả câu: -ly',
            note: 'Vị trí: trước/sau động từ, giữa be và V-ed (is highly recommended), đầu câu (Unfortunately, ...)'),
        GrammarPoint('Động từ (V)', 'sau chủ ngữ | sau modal (can/will/must + V nguyên mẫu) | sau to'),
      ],
      signals: [
        'Có mạo từ a/the/tính từ sở hữu ngay trước chỗ trống → danh từ',
        'Chỗ trống đứng trước danh từ → tính từ',
        'Câu đã đủ chủ ngữ + động từ + tân ngữ → chỗ trống thường là trạng từ',
      ],
      examples: [
        GrammarExample('The manager made a careful decision.', 'Quản lý đưa ra một quyết định cẩn trọng.'),
        GrammarExample('Please handle the boxes carefully.', 'Vui lòng xử lý các thùng hàng cẩn thận.'),
        GrammarExample('The product is highly recommended.', 'Sản phẩm được đánh giá rất cao.'),
        GrammarExample('The company\'s commit to quality is well known.', '(Sai: sau sở hữu cách phải là danh từ "commitment")',
            correct: false),
      ],
      traps: [
        'Đuôi -ly không phải lúc nào cũng là trạng từ: friendly, costly, timely, likely là TÍNH TỪ.',
        'N-er (người) và N-tion (vật/việc) cùng là danh từ - đọc nghĩa câu để chọn: applicant (người nộp) vs application (đơn).',
        'V-ing và V-ed đứng trước danh từ đều làm tính từ: an exciting trip (gây hứng thú) vs excited staff (cảm thấy hào hứng).',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Word form'],
    ),
    GrammarLesson(
      id: 'toeic_tenses',
      track: _toeic,
      level: 'Standard',
      emoji: '⏰',
      title: 'Thì của động từ',
      summary: 'Nhìn TRẠNG TỪ THỜI GIAN trong câu để chọn thì - không cần dịch hết câu.',
      points: [
        GrammarPoint('Hiện tại đơn', 'S + V(s/es) - thói quen, lịch trình, sự thật', note: 'every day, usually, always'),
        GrammarPoint('Hiện tại tiếp diễn', 'S + am/is/are + V-ing', note: 'now, currently, at the moment, Look!'),
        GrammarPoint('Hiện tại hoàn thành', 'S + have/has + V3', note: 'since, for, already, yet, recently, so far, over the past...'),
        GrammarPoint('Quá khứ đơn', 'S + V2/V-ed', note: 'yesterday, last week, ago, in 2020'),
        GrammarPoint('Quá khứ hoàn thành', 'S + had + V3 - xảy ra TRƯỚC 1 mốc quá khứ', note: 'by the time + QKĐ, before, after'),
        GrammarPoint('Tương lai', 'will + V | be going to + V | will have V3 (by + mốc tương lai)',
            note: 'tomorrow, next month, soon, by next year'),
      ],
      signals: [
        '"since/for + khoảng thời gian" → hiện tại hoàn thành',
        '"ago/last/yesterday/in 2019" → quá khứ đơn',
        '"By the time + quá khứ" → quá khứ hoàn thành; "By + mốc tương lai" → tương lai hoàn thành',
        'Mệnh đề thời gian (when/before/after/as soon as/once) nói về tương lai → dùng HIỆN TẠI, không dùng will',
      ],
      examples: [
        GrammarExample('Ms. Kim has worked here since 2015.', 'Bà Kim đã làm việc ở đây từ năm 2015.'),
        GrammarExample('The report was sent three days ago.', 'Báo cáo đã được gửi 3 ngày trước.'),
        GrammarExample('By the time we arrived, the meeting had started.', 'Khi chúng tôi đến, cuộc họp đã bắt đầu.'),
        GrammarExample('Please call me as soon as you will arrive.', '(Sai: sau "as soon as" dùng hiện tại → "you arrive")', correct: false),
      ],
      traps: [
        'Chủ ngữ số ít (The manager, Each employee, Everyone) → động từ thêm s/es hoặc "has".',
        'Chủ ngữ dài có cụm giới từ ở giữa: The list of items IS... (chủ ngữ thật là "list").',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Verb tense'],
    ),
    GrammarLesson(
      id: 'toeic_passive',
      track: _toeic,
      level: 'Standard',
      emoji: '🔄',
      title: 'Câu bị động',
      summary: 'Chủ ngữ là VẬT chịu tác động (báo cáo được gửi, hàng được giao) → dùng bị động.',
      points: [
        GrammarPoint('Công thức chung', 'S + be (chia theo thì) + V3/V-ed (+ by ...)'),
        GrammarPoint('Theo thì', 'is/are sent | was/were sent | has/have been sent | will be sent | is being sent'),
        GrammarPoint('Sau modal', 'must/can/should/will + be + V3', note: 'The form must be signed.'),
      ],
      signals: [
        'Sau chỗ trống KHÔNG có tân ngữ, hoặc có "by + người" → bị động',
        'Chủ ngữ là vật không tự làm được hành động (report, package, meeting) → thường bị động',
      ],
      examples: [
        GrammarExample('The package was delivered yesterday.', 'Gói hàng đã được giao hôm qua.'),
        GrammarExample('All forms must be submitted by Friday.', 'Mọi biểu mẫu phải được nộp trước thứ Sáu.'),
        GrammarExample('The new policy will be announced next week.', 'Chính sách mới sẽ được công bố tuần sau.'),
        GrammarExample('The meeting has postponed until Monday.', '(Sai: cuộc họp "bị" hoãn → "has been postponed")', correct: false),
      ],
      traps: [
        'Nội động từ KHÔNG có bị động: happen, occur, arrive, rise, remain (không nói "was happened").',
        '"be + V-ing" (đang làm, chủ động) khác "be + V3" (được làm, bị động).',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Passive voice'],
    ),
    GrammarLesson(
      id: 'toeic_gerund_inf',
      track: _toeic,
      level: 'Standard',
      emoji: '🔀',
      title: 'V-ing hay to V?',
      summary: 'Học thuộc theo nhóm động từ - rất hay ra ở Part 5.',
      points: [
        GrammarPoint('+ V-ing', 'enjoy, avoid, consider, suggest, recommend, finish, mind, postpone, keep, delay'),
        GrammarPoint('+ to V', 'want, decide, plan, hope, agree, offer, refuse, promise, afford, need, fail'),
        GrammarPoint('+ O + to V', 'ask/allow/advise/encourage/require/remind/invite sb to V',
            note: 'Bị động: be required/asked/encouraged to V'),
        GrammarPoint('Sau giới từ → V-ing', 'interested in, responsible for, before/after/by + V-ing',
            note: 'Chữ "to" là GIỚI TỪ: look forward to, be committed to, be dedicated to + V-ing'),
      ],
      examples: [
        GrammarExample('We are considering opening a new branch.', 'Chúng tôi đang cân nhắc mở chi nhánh mới.'),
        GrammarExample('The board decided to expand into Asia.', 'Hội đồng quyết định mở rộng sang châu Á.'),
        GrammarExample('Employees are required to wear badges.', 'Nhân viên được yêu cầu đeo thẻ.'),
        GrammarExample('I look forward to meet you.', '(Sai: look forward to + V-ing → "to meeting you")', correct: false),
      ],
      traps: [
        'stop/remember/forget + V-ing (việc đã làm) khác + to V (việc sẽ làm / dừng lại để làm).',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Verb form (V-ing/to V)'],
    ),
    GrammarLesson(
      id: 'toeic_conditionals',
      track: _toeic,
      level: 'Standard',
      emoji: '🔮',
      title: 'Câu điều kiện & câu giả định',
      summary: 'Nhận diện loại câu điều kiện qua thì ở 2 vế; sau suggest/request that dùng V nguyên mẫu.',
      points: [
        GrammarPoint('Loại 1 (có thể xảy ra)', 'If + hiện tại đơn, will/can + V', note: 'If it rains, the event will be moved indoors.'),
        GrammarPoint('Loại 2 (không có thật ở hiện tại)', 'If + quá khứ đơn (were), would + V'),
        GrammarPoint('Loại 3 (không có thật ở quá khứ)', 'If + had V3, would have V3'),
        GrammarPoint('Đảo ngữ (hay ra TOEIC)', 'Should you have any questions, ... | Had we known, ... | Were I you, ...'),
        GrammarPoint('Câu giả định (subjunctive)', 'suggest/request/recommend/require that + S + V nguyên mẫu | It is important/essential that + S + V nguyên mẫu',
            note: 'The manager requested that everyone attend. (KHÔNG chia "attends") | ... that the form be signed.'),
      ],
      signals: ['"Should you ..." ở đầu câu = "If you should ..." (nếu bạn có ...)', 'unless = if ... not'],
      examples: [
        GrammarExample('If you have any questions, please contact us.', 'Nếu bạn có câu hỏi, vui lòng liên hệ chúng tôi.'),
        GrammarExample('Should you need assistance, call the front desk.', 'Nếu cần hỗ trợ, hãy gọi quầy lễ tân.'),
        GrammarExample('Had we known about the traffic, we would have left earlier.', 'Nếu biết trước kẹt xe thì chúng tôi đã đi sớm hơn.'),
        GrammarExample('If the weather will be good, we will go.', '(Sai: vế If loại 1 dùng hiện tại → "is good")', correct: false),
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Conditionals & subjunctive'],
    ),
    GrammarLesson(
      id: 'toeic_prepositions',
      track: _toeic,
      level: 'Standard',
      emoji: '📍',
      title: 'Giới từ',
      summary: 'Giới từ thời gian, nơi chốn và các cụm cố định hay gặp.',
      points: [
        GrammarPoint('Thời gian', 'at + giờ | on + thứ/ngày | in + tháng/năm/buổi | for + khoảng | since + mốc'),
        GrammarPoint('Hạn chót vs kéo dài', 'by Friday (trước/chậm nhất) ≠ until Friday (kéo dài đến)'),
        GrammarPoint('Trong khoảng', 'during + N (during the meeting) | within + thời hạn (within 30 days) | throughout'),
        GrammarPoint('Nơi chốn', 'at + điểm (at the front desk) | in + không gian (in the lobby) | on + bề mặt/tầng (on the 3rd floor)'),
        GrammarPoint('Cụm cố định', 'due to, because of, in charge of, in addition to, according to, ahead of schedule, subject to'),
      ],
      examples: [
        GrammarExample('Applications must be submitted by March 31.', 'Hồ sơ phải nộp trước (chậm nhất) ngày 31/3.'),
        GrammarExample('The store will be closed until Monday.', 'Cửa hàng đóng cửa cho tới thứ Hai.'),
        GrammarExample('Refunds are available within 14 days.', 'Được hoàn tiền trong vòng 14 ngày.'),
        GrammarExample('Please don\'t talk during you are in the library.', '(Sai: during + danh từ; mệnh đề dùng "while")', correct: false),
      ],
      traps: [
        'during + danh từ ≠ while + mệnh đề (S + V).',
        'because of/due to + danh từ ≠ because + mệnh đề.',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Prepositions'],
    ),
    GrammarLesson(
      id: 'toeic_conjunctions',
      track: _toeic,
      level: 'Standard',
      emoji: '🔗',
      title: 'Liên từ, giới từ & từ nối',
      summary: 'Nhìn phía sau chỗ trống: MỆNH ĐỀ hay DANH TỪ - rồi mới xét nghĩa.',
      points: [
        GrammarPoint('+ mệnh đề (S + V)', 'although, even though, because, since, while, whereas, unless, once, as soon as'),
        GrammarPoint('+ danh từ/V-ing', 'despite, in spite of, because of, due to, during, without'),
        GrammarPoint('Nối 2 câu (sau dấu ; hoặc đầu câu + ,)', 'however, therefore, moreover, otherwise, nevertheless, in addition'),
        GrammarPoint('Cặp liên từ', 'both A and B | either A or B | neither A nor B | not only A but (also) B'),
      ],
      signals: ['Sau chỗ trống có dấu phẩy và đứng đầu câu thứ 2 → trạng từ nối (However, Therefore...)'],
      examples: [
        GrammarExample('Although it was raining, the event continued.', 'Dù trời mưa, sự kiện vẫn tiếp tục.'),
        GrammarExample('Despite the rain, the event continued.', 'Bất chấp cơn mưa, sự kiện vẫn tiếp tục.'),
        GrammarExample('Submit the form today; otherwise, it may be delayed.', 'Nộp mẫu hôm nay; nếu không có thể bị chậm.'),
        GrammarExample('Despite it was raining, we went out.', '(Sai: despite + danh từ → "Although it was raining")', correct: false),
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Conjunctions & connectors'],
    ),
    GrammarLesson(
      id: 'toeic_pronouns',
      track: _toeic,
      level: 'Standard',
      emoji: '👥',
      title: 'Đại từ & mệnh đề quan hệ',
      summary: 'Chọn đúng dạng đại từ theo VỊ TRÍ và đúng đại từ quan hệ theo từ đứng trước.',
      points: [
        GrammarPoint('Dạng đại từ', 'chủ ngữ: I/he/they | tân ngữ: me/him/them | sở hữu + N: my/his/their | đứng một mình: mine/his/theirs | phản thân: myself/themselves'),
        GrammarPoint('Phản thân', 'by oneself = tự mình | chủ ngữ và tân ngữ là một người: He introduced himself.'),
        GrammarPoint('Quan hệ', 'who (người, làm chủ ngữ) | whom (người, tân ngữ) | which (vật) | that (người/vật) | whose + N (sở hữu) | where (nơi chốn) | when (thời gian)'),
      ],
      examples: [
        GrammarExample('The employee whose idea was chosen will get a bonus.', 'Nhân viên có ý tưởng được chọn sẽ được thưởng.'),
        GrammarExample('Customers who have questions should call us.', 'Khách hàng có câu hỏi nên gọi cho chúng tôi.'),
        GrammarExample('Ms. Lee prepared the slides herself.', 'Bà Lee tự chuẩn bị các slide.'),
        GrammarExample('The company rewards it\'s best employees.', '(Sai: tính từ sở hữu là "its", "it\'s" = it is)', correct: false),
      ],
      traps: ['Sau dấu phẩy KHÔNG dùng "that" (..., which ...).', 'its (của nó) ≠ it\'s (it is).'],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Pronouns & relatives'],
    ),
    GrammarLesson(
      id: 'toeic_comparatives',
      track: _toeic,
      level: 'Standard',
      emoji: '📊',
      title: 'So sánh & lượng từ',
      summary: 'So sánh hơn/nhất/bằng và các từ chỉ số lượng đi với danh từ đếm được/không đếm được.',
      points: [
        GrammarPoint('So sánh hơn', 'adj-er + than | more + adj dài + than', note: 'Nhấn mạnh: much/far/even/significantly + so sánh hơn'),
        GrammarPoint('So sánh nhất', 'the + adj-est | the most + adj (+ in/of ...)'),
        GrammarPoint('So sánh bằng', 'as + adj/adv + as | twice/three times as ... as'),
        GrammarPoint('Càng... càng', 'The + so sánh hơn ..., the + so sánh hơn ...'),
        GrammarPoint('Lượng từ', 'each/every + N số ít | many/few/a few + N đếm được số nhiều | much/little/a little + N không đếm được | all/most/some of the + N'),
      ],
      examples: [
        GrammarExample('This model is much lighter than the old one.', 'Mẫu này nhẹ hơn nhiều so với mẫu cũ.'),
        GrammarExample('Sales were twice as high as last year.', 'Doanh số cao gấp đôi năm ngoái.'),
        GrammarExample('Each employee has a parking pass.', 'Mỗi nhân viên có một thẻ đỗ xe.'),
        GrammarExample('We received few information about the plan.', '(Sai: information không đếm được → "little information")', correct: false),
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Comparatives & determiners'],
    ),

    GrammarLesson(
      id: 'toeic_agreement',
      track: _toeic,
      level: 'Standard',
      emoji: '⚖️',
      title: 'Hoà hợp chủ ngữ – động từ',
      summary: 'Tìm đúng CHỦ NGỮ THẬT rồi chia động từ số ít hay số nhiều - bẫy rất hay gặp ở Part 5.',
      points: [
        GrammarPoint('Chủ ngữ có cụm bổ nghĩa ở giữa', 'The list of items IS... | The members, along with their manager, ARE...',
            note: 'Bỏ qua cụm "of ...", "along with/as well as/together with ..." để tìm chủ ngữ thật'),
        GrammarPoint('Luôn số ít', 'each/every + N | everyone, anyone, someone, nobody | the number of + N | N không đếm được (information, furniture, equipment)'),
        GrammarPoint('Luôn số nhiều', 'a number of + N | both A and B | several/many + N'),
        GrammarPoint('Chia theo danh từ GẦN NHẤT', 'either A or B | neither A nor B | not only A but also B'),
        GrammarPoint('Most/Some/All of + N', 'chia theo danh từ sau "of": most of the staff/information IS, most of the employees ARE'),
      ],
      signals: [
        'Chỗ trống là is/are, has/have, was/were → đi tìm chủ ngữ thật',
        'Đại từ quan hệ who/which/that → chia theo danh từ đứng ngay trước nó',
      ],
      examples: [
        GrammarExample('The number of applicants has increased this year.', 'Số lượng ứng viên năm nay đã tăng.'),
        GrammarExample('A number of employees have asked for flexible hours.', 'Một số nhân viên đã xin giờ làm linh hoạt.'),
        GrammarExample('Neither the manager nor her assistants are available.', 'Cả quản lý lẫn các trợ lý đều không rảnh.'),
        GrammarExample('Every employee and manager are required to attend.', '(Sai: every ... and ... → "is required")', correct: false),
      ],
      traps: [
        '"The number of" (số lượng - số ít) khác "A number of" (nhiều - số nhiều).',
        'staff/team có thể chia số ít; nhưng "the staff members" luôn số nhiều.',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Subject-verb agreement'],
    ),
    GrammarLesson(
      id: 'toeic_confusing_words',
      track: _toeic,
      level: 'Standard',
      emoji: '🪞',
      title: 'Cặp từ dễ nhầm & collocation',
      summary: 'Câu từ vựng Part 5 hay đưa 4 từ na ná nhau - phân biệt bằng NGHĨA, TỪ LOẠI và TỪ ĐI KÈM.',
      points: [
        GrammarPoint('affect / effect', 'affect (V) = ảnh hưởng tới | effect (N) = tác động; take effect = có hiệu lực',
            note: 'The rain affected sales. / The change had a positive effect on sales.'),
        GrammarPoint('rise / raise', 'rise (tự tăng, KHÔNG có tân ngữ) | raise + tân ngữ (nâng, tăng cái gì)',
            note: 'Prices rose. / The company raised prices.'),
        GrammarPoint('lend / borrow', 'lend sb sth = cho ai mượn | borrow sth from sb = mượn của ai'),
        GrammarPoint('say / tell', 'say (that) ... | tell sb (that) ... - tell cần tân ngữ người'),
        GrammarPoint('Collocation hay ra', 'meet a deadline | place an order | make a reservation | conduct a survey | '
            'extend a contract | take effect | follow the rules | apologize for the inconvenience'),
      ],
      signals: [
        'Chỗ trống có tân ngữ theo sau → động từ ngoại động (raise, lay, lend)',
        '4 đáp án khác nghĩa nhưng cùng từ loại → dịch cụm từ đi kèm trước/sau chỗ trống',
      ],
      examples: [
        GrammarExample('The new policy will affect all employees.', 'Chính sách mới sẽ ảnh hưởng tới mọi nhân viên.'),
        GrammarExample('The company plans to raise prices next year.', 'Công ty dự định tăng giá năm sau.'),
        GrammarExample('Could you lend me your pen?', 'Bạn cho tôi mượn cây bút được không?'),
        GrammarExample('She said me that the meeting was canceled.', '(Sai: said me → told me)', correct: false),
      ],
      traps: [
        'Những cặp từ viết gần giống nhau: adapt/adopt, precede/proceed, complement/compliment, stationary/stationery.',
        'Đọc TOÀN câu trước khi chọn: nghĩa đúng nhưng sai collocation vẫn là đáp án sai (make a deadline ✗ → meet a deadline ✓).',
      ],
      practiceSkill: Skill.reading,
      practicePart: 5,
      practiceTopics: ['Vocabulary'],
    ),
    GrammarLesson(
      id: 'toeic_part6_insertion',
      track: _toeic,
      level: 'Standard',
      emoji: '🧱',
      title: 'Part 6: chọn câu chèn vào đoạn văn',
      summary: 'Chiến thuật cho dạng câu khó nhất Part 6 - chọn 1 trong 4 câu hoàn chỉnh để điền vào chỗ trống.',
      points: [
        GrammarPoint('Bước 1 - Đọc câu TRƯỚC và SAU chỗ trống', 'câu cần chèn phải nối được cả 2 phía, không chỉ 1 phía'),
        GrammarPoint('Bước 2 - Tìm "móc nối"', 'đại từ (this, these, it, they), từ nối (however, also, in addition), từ lặp lại chủ đề',
            note: 'Câu bắt đầu bằng "This ..."/"These ..." phải có thứ để "this/these" chỉ tới ngay trước nó.'),
        GrammarPoint('Bước 3 - Loại đáp án lạc chủ đề', 'câu đúng ngữ pháp nhưng nói chuyện khác hẳn (công ty thành lập năm nào, bãi đỗ xe...) → loại'),
        GrammarPoint('Bước 4 - Kiểm tra thì & mục đích văn bản', 'thư xin lỗi, thông báo, quảng cáo... câu chèn phải cùng giọng điệu và mốc thời gian'),
      ],
      examples: [
        GrammarExample('The chairs are delayed. In the meantime, we can offer you a similar model.',
            'Ghế bị chậm giao. Trong lúc chờ, chúng tôi có thể đưa bạn một mẫu tương tự.'),
        GrammarExample('Our hours will change on January 1. Weekend hours will remain the same.',
            'Giờ mở cửa thay đổi từ 1/1. Giờ cuối tuần giữ nguyên.'),
        GrammarExample('The chairs are delayed. Our company was founded in 1998.',
            '(Sai: đúng ngữ pháp nhưng lạc chủ đề thư)', correct: false),
      ],
      traps: [
        'Đáp án nhắc lại TỪ trong đoạn văn chưa chắc đúng - phải đúng MẠCH Ý.',
        'Chỗ trống ở cuối thư thường là câu kết/kêu gọi hành động (Please contact us..., We look forward to...).',
      ],
      practiceSkill: Skill.reading,
      practicePart: 6,
      practiceTopics: ['Sentence insertion'],
    ),

    // ================================================================ MOVERS
    GrammarLesson(
      id: 'mov_present',
      track: _yle,
      level: 'Movers',
      emoji: '☀️',
      title: 'Hiện tại đơn & hiện tại tiếp diễn',
      summary: 'Việc làm HẰNG NGÀY dùng hiện tại đơn; việc ĐANG làm lúc này dùng hiện tại tiếp diễn.',
      points: [
        GrammarPoint('Hiện tại đơn', 'I/You/We/They + play | He/She/It + plays', note: 'go → goes, watch → watches, study → studies'),
        GrammarPoint('Phủ định & câu hỏi', 'He doesn\'t play. | Does he play?', note: 'Sau does/doesn\'t động từ KHÔNG thêm s'),
        GrammarPoint('Hiện tại tiếp diễn', 'am/is/are + V-ing', note: 'Look! / Listen! / now'),
        GrammarPoint('Trạng từ tần suất', 'always > usually > often > sometimes > never', note: 'Đứng trước động từ thường: I always brush my teeth.'),
      ],
      examples: [
        GrammarExample('She goes to school every day.', 'Bạn ấy đi học mỗi ngày.'),
        GrammarExample('Look! The baby is sleeping.', 'Nhìn kìa! Em bé đang ngủ.'),
        GrammarExample('I never eat vegetables.', 'Tớ không bao giờ ăn rau.'),
        GrammarExample('He don\'t like apples.', '(Sai → He doesn\'t like apples.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Present Simple', 'Present Continuous', 'Adverbs of Frequency', 'Negatives'],
    ),
    GrammarLesson(
      id: 'mov_past',
      track: _yle,
      level: 'Movers',
      emoji: '📅',
      title: 'Quá khứ đơn',
      summary: 'Kể chuyện ĐÃ xảy ra: yesterday, last week, ago...',
      points: [
        GrammarPoint('Động từ có quy tắc', 'thêm -ed: play → played, watch → watched, study → studied'),
        GrammarPoint('Động từ bất quy tắc', 'go → went, see → saw, eat → ate, have → had, make → made, take → took, run → ran'),
        GrammarPoint('Phủ định & câu hỏi', 'I didn\'t go. | Did you go?', note: 'Sau did/didn\'t dùng động từ nguyên mẫu'),
        GrammarPoint('Động từ "be"', 'I/he/she/it was | you/we/they were'),
      ],
      examples: [
        GrammarExample('We went to the beach yesterday.', 'Hôm qua chúng mình đi biển.'),
        GrammarExample('Did you see the elephants?', 'Bạn có thấy những con voi không?'),
        GrammarExample('I didn\'t watch TV last night.', 'Tối qua tớ không xem TV.'),
        GrammarExample('I didn\'t went to school.', '(Sai → I didn\'t go to school.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Past Simple', 'Past Simple Negative'],
    ),
    GrammarLesson(
      id: 'mov_compare',
      track: _yle,
      level: 'Movers',
      emoji: '🐘',
      title: 'So sánh hơn & so sánh nhất',
      summary: 'Con voi TO HƠN con ngựa. Cá voi xanh TO NHẤT.',
      points: [
        GrammarPoint('Từ ngắn', 'big → bigger → the biggest | tall → taller → the tallest', note: 'Nhân đôi phụ âm: big, hot, fat'),
        GrammarPoint('Tận cùng -y', 'happy → happier → the happiest | heavy → heavier'),
        GrammarPoint('Từ dài', 'beautiful → more beautiful → the most beautiful'),
        GrammarPoint('Đặc biệt', 'good → better → the best | bad → worse → the worst'),
      ],
      examples: [
        GrammarExample('An elephant is bigger than a horse.', 'Con voi to hơn con ngựa.'),
        GrammarExample('This is the best day of the year!', 'Đây là ngày tuyệt nhất trong năm!'),
        GrammarExample('My book is more interesting than yours.', 'Sách của tớ thú vị hơn sách của cậu.'),
        GrammarExample('He is more tall than me.', '(Sai → He is taller than me.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Comparatives', 'Superlatives'],
    ),
    GrammarLesson(
      id: 'mov_questions',
      track: _yle,
      level: 'Movers',
      emoji: '❓',
      title: 'Từ để hỏi',
      summary: 'Nghe câu trả lời để đoán từ để hỏi.',
      points: [
        GrammarPoint('Who / What / Where / When', 'Ai / Cái gì / Ở đâu / Khi nào'),
        GrammarPoint('Why → Because ...', 'Hỏi lý do'),
        GrammarPoint('How / How many / How much / How old', 'Thế nào, bằng cách nào / bao nhiêu (đếm được) / bao nhiêu (không đếm được, giá tiền) / mấy tuổi'),
        GrammarPoint('Which / Whose', 'Cái nào / Của ai'),
      ],
      examples: [
        GrammarExample('Where is the bus stop? – Next to the park.', 'Trạm xe buýt ở đâu? – Cạnh công viên.'),
        GrammarExample('How do you go to school? – By bus.', 'Bạn đi học bằng gì? – Bằng xe buýt.'),
        GrammarExample('Why are you crying? – Because I hurt my knee.', 'Sao bạn khóc? – Vì tớ đau đầu gối.'),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Question Words', 'Question Formation'],
    ),
    GrammarLesson(
      id: 'mov_quantity',
      track: _yle,
      level: 'Movers',
      emoji: '🍎',
      title: 'Số nhiều, some/any, much/many',
      summary: 'Đếm được hay không đếm được? Câu khẳng định hay câu hỏi?',
      points: [
        GrammarPoint('Số nhiều', 'cat → cats | box → boxes | baby → babies',
            note: 'Bất quy tắc: child → children, mouse → mice, foot → feet, tooth → teeth, sheep → sheep'),
        GrammarPoint('There is / There are', 'There is + 1 vật | There are + nhiều vật'),
        GrammarPoint('some / any', 'some: câu khẳng định | any: câu hỏi và phủ định'),
        GrammarPoint('many / much', 'many + đếm được (apples) | much + không đếm được (water, milk)'),
      ],
      examples: [
        GrammarExample('There are three children in the park.', 'Có 3 bạn nhỏ trong công viên.'),
        GrammarExample('Is there any milk in the fridge?', 'Trong tủ lạnh có sữa không?'),
        GrammarExample('How much water do you drink?', 'Bạn uống bao nhiêu nước?'),
        GrammarExample('I have two mouses.', '(Sai → two mice)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Plurals', 'Some/Any', 'Much/Many', 'Countable/Uncountable', 'There is/are'],
    ),
    GrammarLesson(
      id: 'mov_prepositions',
      track: _yle,
      level: 'Movers',
      emoji: '📦',
      title: 'Giới từ chỉ nơi chốn & thời gian',
      summary: 'Con mèo ở ĐÂU? Sinh nhật vào KHI NÀO?',
      points: [
        GrammarPoint('Nơi chốn', 'in (trong) | on (trên) | under (dưới) | behind (sau) | in front of (trước) | next to (cạnh) | between (giữa)'),
        GrammarPoint('Thời gian', 'at + giờ (at 7 o\'clock) | on + thứ (on Monday) | in + tháng/năm/mùa (in July)'),
      ],
      examples: [
        GrammarExample('The cat is under the table.', 'Con mèo ở dưới gầm bàn.'),
        GrammarExample('The bank is between the café and the shop.', 'Ngân hàng nằm giữa quán cà phê và cửa hàng.'),
        GrammarExample('My birthday is in July.', 'Sinh nhật tớ vào tháng Bảy.'),
        GrammarExample('We have lunch on 12 o\'clock.', '(Sai → at 12 o\'clock)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Prepositions of Place', 'Prepositions of Time', 'Prepositions'],
    ),
    GrammarLesson(
      id: 'mov_pronouns',
      track: _yle,
      level: 'Movers',
      emoji: '🙋',
      title: 'Đại từ & sở hữu',
      summary: 'I – me – my – mine: mỗi từ đứng một chỗ khác nhau.',
      points: [
        GrammarPoint('Chủ ngữ', 'I, you, he, she, it, we, they'),
        GrammarPoint('Tân ngữ (sau động từ)', 'me, you, him, her, it, us, them'),
        GrammarPoint('Sở hữu + danh từ', 'my, your, his, her, its, our, their + dog'),
        GrammarPoint('Sở hữu đứng một mình', 'mine, yours, his, hers, ours, theirs', note: 'Whose shoes are these? – They\'re mine.'),
        GrammarPoint('\'s sở hữu', 'Tom\'s bike = xe đạp của Tom'),
      ],
      examples: [
        GrammarExample('I love my grandma. I visit her every week.', 'Tớ yêu bà. Tớ thăm bà mỗi tuần.'),
        GrammarExample('This is our dog. Its name is Rex.', 'Đây là con chó của chúng tớ. Tên nó là Rex.'),
        GrammarExample('He plays with I.', '(Sai → He plays with me.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Object Pronouns', 'Possessives', "Possessive 's", 'Reflexive Pronouns'],
    ),
    GrammarLesson(
      id: 'mov_modals',
      track: _yle,
      level: 'Movers',
      emoji: '🚦',
      title: 'going to, would like, must',
      summary: 'Nói về dự định, lời mời và điều bắt buộc.',
      points: [
        GrammarPoint('be going to + V', 'dự định / dự đoán có dấu hiệu', note: 'Look at the clouds! It is going to rain.'),
        GrammarPoint('Would you like ...?', 'lời mời lịch sự: Would you like some juice? – Yes, please.'),
        GrammarPoint('must / mustn\'t', 'phải làm / không được làm',
            note: 'You mustn\'t run near the pool. Sau must dùng động từ nguyên mẫu.'),
      ],
      examples: [
        GrammarExample('We are going to visit Grandma tomorrow.', 'Ngày mai chúng mình sẽ thăm bà.'),
        GrammarExample('You must wear a helmet.', 'Bạn phải đội mũ bảo hiểm.'),
        GrammarExample('Would you like some juice? – Yes, please.', 'Bạn uống chút nước ép nhé? – Vâng ạ.'),
        GrammarExample('You must to wear a helmet.', '(Sai: sau must không có "to" → You must wear a helmet.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Going to Future', 'Would Like', 'Must/Have to', 'Modals', 'Modal Verbs'],
    ),

    GrammarLesson(
      id: 'mov_can_imperatives',
      track: _yle,
      level: 'Movers',
      emoji: '🏊',
      title: 'can / can\'t & câu mệnh lệnh',
      summary: 'Nói bé làm được gì, và bảo ai đó làm / đừng làm gì.',
      points: [
        GrammarPoint('can / can\'t + V', 'có thể / không thể', note: 'I can swim. Fish can\'t walk. Can you ride a bike? – Yes, I can.'),
        GrammarPoint('Câu mệnh lệnh', 'V nguyên mẫu ở đầu câu', note: 'Close the door, please. / Be quiet!'),
        GrammarPoint('Mệnh lệnh phủ định', 'Don\'t + V', note: 'Don\'t run in the classroom!'),
      ],
      examples: [
        GrammarExample('My brother can swim, but he can\'t dive.', 'Anh tớ biết bơi nhưng không biết lặn.'),
        GrammarExample('Wash your hands before dinner.', 'Rửa tay trước bữa tối nhé.'),
        GrammarExample('Don\'t touch the hot cup!', 'Đừng chạm vào cốc nóng!'),
        GrammarExample('He can swims.', '(Sai: sau can dùng V nguyên mẫu → He can swim.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Can for Ability', 'Imperatives', 'Imperative Negative'],
    ),
    GrammarLesson(
      id: 'mov_articles_this',
      track: _yle,
      level: 'Movers',
      emoji: '👉',
      title: 'a / an / the & this / that',
      summary: 'Chọn a hay an, khi nào dùng the; chỉ vật ở gần hay ở xa.',
      points: [
        GrammarPoint('a / an', 'a + phụ âm (a dog) | an + nguyên âm a, e, i, o, u (an apple, an elephant)'),
        GrammarPoint('the', 'vật duy nhất (the sun, the moon) | vật đã nói tới trước đó'),
        GrammarPoint('Gần', 'this + 1 vật | these + nhiều vật'),
        GrammarPoint('Xa', 'that + 1 vật | those + nhiều vật'),
      ],
      examples: [
        GrammarExample('I saw an elephant and a giraffe.', 'Tớ thấy một con voi và một con hươu cao cổ.'),
        GrammarExample('Look at the moon!', 'Nhìn mặt trăng kìa!'),
        GrammarExample('These are my shoes. Those are yours.', 'Đây là giày của tớ. Kia là của cậu.'),
        GrammarExample('I have a orange.', '(Sai → an orange)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Articles', 'This/That/These/Those'],
    ),
    GrammarLesson(
      id: 'mov_conjunctions',
      track: _yle,
      level: 'Movers',
      emoji: '🧷',
      title: 'and / but / or / so / because',
      summary: 'Nối 2 ý thành 1 câu dài hơn.',
      points: [
        GrammarPoint('and', 'thêm ý: I like apples and bananas.'),
        GrammarPoint('but', 'ý trái ngược: I like apples, but I don\'t like pears.'),
        GrammarPoint('or', 'lựa chọn: Do you want tea or juice?'),
        GrammarPoint('so / because', 'so = vì vậy (kết quả) | because = bởi vì (lý do)'),
      ],
      examples: [
        GrammarExample('I was hungry, so I ate a sandwich.', 'Tớ đói nên tớ ăn bánh mì.'),
        GrammarExample('I ate a sandwich because I was hungry.', 'Tớ ăn bánh mì vì tớ đói.'),
        GrammarExample('I want to go out, but it\'s raining.', 'Tớ muốn ra ngoài nhưng trời đang mưa.'),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Conjunctions'],
    ),

    // ================================================================ FLYERS
    GrammarLesson(
      id: 'fly_present_perfect',
      track: _yle,
      level: 'Flyers',
      emoji: '✅',
      title: 'Hiện tại hoàn thành',
      summary: 'Đã từng / đã xong / kéo dài từ quá khứ đến bây giờ.',
      points: [
        GrammarPoint('Công thức', 'have/has + V3', note: 'eat → eaten, see → seen, go → gone/been, ride → ridden'),
        GrammarPoint('Dấu hiệu', 'ever, never, already, just, yet, since + mốc, for + khoảng thời gian'),
        GrammarPoint('Hỏi', 'Have you ever ...? | How long have you ...?'),
      ],
      examples: [
        GrammarExample('I have never ridden a camel.', 'Tớ chưa bao giờ cưỡi lạc đà.'),
        GrammarExample('She has lived in London since 2020.', 'Cô ấy sống ở London từ năm 2020.'),
        GrammarExample('Have you finished your homework yet?', 'Bạn làm xong bài tập chưa?'),
        GrammarExample('I have seen that film yesterday.', '(Sai: có "yesterday" → quá khứ đơn: I saw that film yesterday.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Present Perfect'],
    ),
    GrammarLesson(
      id: 'fly_past_continuous',
      track: _yle,
      level: 'Flyers',
      emoji: '🎬',
      title: 'Quá khứ tiếp diễn & used to',
      summary: 'Đang làm gì thì có chuyện xảy ra; thói quen ngày xưa.',
      points: [
        GrammarPoint('Quá khứ tiếp diễn', 'was/were + V-ing', note: 'What were you doing at 8 o\'clock?'),
        GrammarPoint('Đang làm thì bị cắt ngang', 'While + QKTD, QKĐ | QKTD when + QKĐ', note: 'I was watching TV when the phone rang.'),
        GrammarPoint('used to + V', 'thói quen/tình trạng trong quá khứ, bây giờ không còn'),
      ],
      examples: [
        GrammarExample('While we were having dinner, the lights went out.', 'Khi cả nhà đang ăn tối thì mất điện.'),
        GrammarExample('I used to be afraid of the dark.', 'Hồi trước tớ từng sợ bóng tối.'),
        GrammarExample('I use to play with dolls when I was little.', '(Sai → used to)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Past Continuous', 'Used To'],
    ),
    GrammarLesson(
      id: 'fly_passive',
      track: _yle,
      level: 'Flyers',
      emoji: '🏰',
      title: 'Câu bị động',
      summary: 'Nói về vật ĐƯỢC làm ra: Lâu đài được xây, phô mai được làm từ sữa.',
      points: [
        GrammarPoint('Hiện tại', 'is/are + V3', note: 'Cheese is made from milk.'),
        GrammarPoint('Quá khứ', 'was/were + V3', note: 'The castle was built 500 years ago.'),
        GrammarPoint('Người làm', '... by + người', note: 'The Mona Lisa was painted by Leonardo da Vinci.'),
      ],
      examples: [
        GrammarExample('English is spoken in many countries.', 'Tiếng Anh được nói ở nhiều nước.'),
        GrammarExample('This bridge was built in 1890.', 'Cây cầu này được xây năm 1890.'),
        GrammarExample('The letters delivered every morning.', '(Sai → are delivered)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Passive Voice'],
    ),
    GrammarLesson(
      id: 'fly_conditionals',
      track: _yle,
      level: 'Flyers',
      emoji: '🌈',
      title: 'Câu điều kiện',
      summary: 'NẾU ... THÌ ...: điều có thật và điều tưởng tượng.',
      points: [
        GrammarPoint('Loại 0 - sự thật', 'If + hiện tại, hiện tại', note: 'If you heat ice, it melts.'),
        GrammarPoint('Loại 1 - có thể xảy ra', 'If + hiện tại, will + V', note: 'If it rains, we will stay at home.'),
        GrammarPoint('Loại 2 - tưởng tượng', 'If + quá khứ (were), would + V', note: 'If I were a bird, I would fly.'),
      ],
      examples: [
        GrammarExample('If you study hard, you will pass the test.', 'Nếu học chăm, bạn sẽ đỗ bài kiểm tra.'),
        GrammarExample('If I had wings, I would fly to school.', 'Nếu tớ có cánh, tớ sẽ bay đến trường.'),
        GrammarExample('If it will rain, we will stay home.', '(Sai → If it rains, ...)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Conditionals', 'Second Conditional'],
    ),
    GrammarLesson(
      id: 'fly_relative',
      track: _yle,
      level: 'Flyers',
      emoji: '🔗',
      title: 'Mệnh đề quan hệ',
      summary: 'Nối 2 câu bằng who / which / that / whose / where.',
      points: [
        GrammarPoint('who', 'chỉ người', note: 'That\'s the girl who won the competition.'),
        GrammarPoint('which / that', 'chỉ vật', note: 'This is the book that I told you about.'),
        GrammarPoint('whose + danh từ', 'của người đó', note: 'He\'s the boy whose dad is a pilot.'),
        GrammarPoint('where', 'chỉ nơi chốn', note: 'This is the park where we play football.'),
      ],
      examples: [
        GrammarExample('The man who lives next door is a doctor.', 'Người đàn ông sống cạnh nhà là bác sĩ.'),
        GrammarExample('I lost the pen which my dad gave me.', 'Tớ làm mất cây bút bố tặng.'),
        GrammarExample('This is the girl which sings well.', '(Sai: chỉ người dùng "who")', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Relative Clauses'],
    ),
    GrammarLesson(
      id: 'fly_question_tags',
      track: _yle,
      level: 'Flyers',
      emoji: '🏷️',
      title: 'Câu hỏi đuôi',
      summary: '..., phải không? Khẳng định thì đuôi phủ định và ngược lại.',
      points: [
        GrammarPoint('Quy tắc', 'Câu khẳng định → đuôi phủ định | Câu phủ định → đuôi khẳng định'),
        GrammarPoint('Dùng lại trợ động từ', 'is → isn\'t | can\'t → can | like (hiện tại) → don\'t | went (quá khứ) → didn\'t'),
      ],
      examples: [
        GrammarExample('It\'s cold today, isn\'t it?', 'Hôm nay lạnh nhỉ?'),
        GrammarExample('She can\'t swim, can she?', 'Bạn ấy không biết bơi, phải không?'),
        GrammarExample('You went to the party, didn\'t you?', 'Bạn đã đi dự tiệc, phải không?'),
        GrammarExample('You like chocolate, do you?', '(Sai → don\'t you?)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Question Tags'],
    ),
    GrammarLesson(
      id: 'fly_verb_patterns',
      track: _yle,
      level: 'Flyers',
      emoji: '🧗',
      title: 'V-ing / to V, too / enough',
      summary: 'Sau một số động từ phải dùng V-ing, số khác dùng to V.',
      points: [
        GrammarPoint('+ V-ing', 'enjoy, mind, finish, like/love/hate', note: 'I enjoy reading books.'),
        GrammarPoint('+ to V', 'want, hope, decide, need, would like', note: 'I hope to visit Japan.'),
        GrammarPoint('too + adj (+ to V)', 'quá ... (nên không làm được)', note: 'The water is too cold to swim in.'),
        GrammarPoint('adj + enough (+ to V)', 'đủ ... để', note: 'He isn\'t tall enough to reach the shelf.'),
      ],
      examples: [
        GrammarExample('Would you mind opening the window?', 'Bạn có phiền mở cửa sổ không?'),
        GrammarExample('We decided to have a picnic.', 'Chúng mình quyết định đi dã ngoại.'),
        GrammarExample('He is enough tall.', '(Sai → tall enough)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Gerunds vs Infinitives', 'Too/Enough'],
    ),
    GrammarLesson(
      id: 'fly_reported_deduction',
      track: _yle,
      level: 'Flyers',
      emoji: '🕵️',
      title: 'Câu tường thuật & phỏng đoán',
      summary: 'Kể lại lời người khác nói; đoán chắc chắn bằng must / can\'t.',
      points: [
        GrammarPoint('Câu tường thuật: lùi thì', 'is → was | have → had | can → could | will → would',
            note: '"I am tired," Tom said. → Tom said that he was tired.'),
        GrammarPoint('must be', 'chắc chắn là (có bằng chứng)', note: 'Mum\'s car isn\'t here. She must be at work.'),
        GrammarPoint('can\'t be', 'chắc chắn không phải', note: 'That can\'t be Tom\'s bike - his is red.'),
      ],
      examples: [
        GrammarExample('She told me that she had a new puppy.', 'Bạn ấy kể với tớ là bạn ấy có một chú cún mới.'),
        GrammarExample('He must be hungry. He hasn\'t eaten all day.', 'Chắc chắn cậu ấy đói. Cả ngày chưa ăn gì.'),
        GrammarExample('Tom said that he is tired.', '(Sai trong câu tường thuật → he was tired)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Reported Speech', 'Modals of Deduction'],
    ),
    GrammarLesson(
      id: 'fly_future',
      track: _yle,
      level: 'Flyers',
      emoji: '🚀',
      title: 'Tương lai: will & be going to',
      summary: 'Nói về chuyện SẼ xảy ra - chọn will hay be going to?',
      points: [
        GrammarPoint('will + V', 'dự đoán (I think it will rain) | quyết định ngay lúc nói (I\'ll answer it!) | hứa hẹn'),
        GrammarPoint('be going to + V', 'kế hoạch đã định trước | dự đoán có dấu hiệu rõ ràng',
            note: 'We\'re going to visit Grandma - we bought the tickets. / Look at the clouds! It\'s going to rain.'),
        GrammarPoint('Phủ định & câu hỏi', 'won\'t + V | Will you ...? | I\'m not going to ... | Are you going to ...?'),
      ],
      examples: [
        GrammarExample('I think you will enjoy the film.', 'Tớ nghĩ cậu sẽ thích bộ phim.'),
        GrammarExample('The phone is ringing. – I\'ll answer it!', 'Điện thoại reo kìa. – Để tớ nghe!'),
        GrammarExample('Look at that boy! He is going to fall.', 'Nhìn cậu bé kia! Cậu ấy sắp ngã rồi.'),
        GrammarExample('I will to call you tomorrow.', '(Sai: sau will không có "to" → I will call you.)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Future Tense'],
    ),
    GrammarLesson(
      id: 'fly_articles_pronouns',
      track: _yle,
      level: 'Flyers',
      emoji: '🔍',
      title: 'Mạo từ & someone / anything / nothing',
      summary: 'Khi nào dùng a/an/the/không dùng; và các từ "ai đó, cái gì đó, không có gì".',
      points: [
        GrammarPoint('the', 'vật duy nhất (the sun) | nhạc cụ (play the guitar) | vật đã biết'),
        GrammarPoint('Không mạo từ', 'tên thành phố, nước (Paris, Japan) | môn thể thao (play football) | bữa ăn (have lunch)'),
        GrammarPoint('some- (câu khẳng định)', 'someone, something, somewhere'),
        GrammarPoint('any- (câu hỏi, phủ định)', 'anyone, anything, anywhere'),
        GrammarPoint('no- / every-', 'nothing, no one, nowhere (= không) | everyone, everything, everywhere (= tất cả)',
            note: 'Động từ đi sau chia số ít: Everyone likes pizza.'),
      ],
      examples: [
        GrammarExample('Can you play the guitar?', 'Bạn có chơi được đàn ghi-ta không?'),
        GrammarExample('Is there anything interesting on TV?', 'Trên TV có gì hay không?'),
        GrammarExample('Everyone in my class likes pizza.', 'Cả lớp tớ ai cũng thích pizza.'),
        GrammarExample('I can\'t find my keys nowhere.', '(Sai: đã có can\'t → anywhere)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Articles', 'Indefinite Pronouns'],
    ),
    GrammarLesson(
      id: 'fly_adverbs_compare',
      track: _yle,
      level: 'Flyers',
      emoji: '🏃',
      title: 'Trạng từ & so sánh',
      summary: 'Chạy NHANH, hát HAY - và so sánh ai hơn ai.',
      points: [
        GrammarPoint('Trạng từ chỉ cách thức', 'adj + ly: slow → slowly, careful → carefully, happy → happily',
            note: 'Bất quy tắc: good → well, fast → fast, hard → hard'),
        GrammarPoint('Vị trí', 'thường đứng SAU động từ (và tân ngữ): She sings beautifully.'),
        GrammarPoint('So sánh hơn / nhất', 'faster / the fastest | more interesting / the most interesting | good → better → the best'),
      ],
      examples: [
        GrammarExample('The tortoise walks very slowly.', 'Con rùa bò rất chậm.'),
        GrammarExample('She sings well.', 'Bạn ấy hát hay.'),
        GrammarExample('A plane is faster than a train.', 'Máy bay nhanh hơn tàu hoả.'),
        GrammarExample('He runs very quick.', '(Sai: bổ nghĩa cho động từ → quickly)', correct: false),
      ],
      practiceSkill: Skill.grammar,
      practiceTopics: ['Adverbs of Manner', 'Comparatives', 'Superlatives'],
    ),
  ];
}
