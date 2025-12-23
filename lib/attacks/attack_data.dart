// lib/attacks/attack_data.dart
import 'attack_model.dart';

class AttackData {
  static const List<AttackModel> items = [
    // 1–3 ay: daha kısa pencere
    AttackModel(
      month: 1,
      windowStartDays: 6,
      windowEndDays: 8,
      title: '1. Ay Dönemi',
      description:
          'Gün–gece ritmi oturmaya çalışır; temas ve sakinleşme ihtiyacı artabilir.',
      symptoms: [
        'Akşam saatlerinde huzursuzluk',
        'Sık beslenme isteği',
        'Kısa uyku blokları',
      ],
      tips: [
        'Işığı akşam azalt, gündüz daha aydınlık tut.',
        'Rutinleri çok basit tut.',
        'Aşırı uyaranı azalt.',
      ],
    ),
    AttackModel(
      month: 2,
      windowStartDays: 6,
      windowEndDays: 8,
      title: '2. Ay Dönemi',
      description: 'Uyanıklık artabilir; daha fazla ilgi ve kucak isteyebilir.',
      symptoms: [
        'Daha zor sakinleşme',
        'Kısa gündüz uykuları',
        'Daha sık uyanma',
      ],
      tips: [
        'Uyku öncesi mini ritüel (kısa ve tutarlı).',
        'Gaz/rahatsızlık tetiklerini gözle.',
        'Uykuyu kaçırmamaya çalış.',
      ],
    ),
    AttackModel(
      month: 3,
      windowStartDays: 7,
      windowEndDays: 9,
      title: '3. Ay Dönemi',
      description:
          'Duyusal farkındalık artar; çevre daha “ilginç” hale gelir, uyku bölünebilir.',
      symptoms: [
        'Uykuya dalmada zorlanma',
        'Daha kolay dikkatin dağılması',
        'Gündüz şekerlemelerinde kısalma',
      ],
      tips: [
        'Uyku ortamını sadeleştir (karanlık/sakin).',
        'Aynı sırayla rutin uygula.',
        'Aşırı yorulmayı önle.',
      ],
    ),

    // 4–12 ay: standart pencere
    AttackModel(
      month: 4,
      windowStartDays: 7,
      windowEndDays: 10,
      title: '4. Ay Dönemi',
      description:
          'Daha uyanık, daha meraklı ve daha “talepkâr” olabilir; uyku düzeni dalgalanabilir.',
      symptoms: [
        'Daha sık huysuzluk',
        'Sık uyanma',
        'Daha fazla temas ihtiyacı',
        'Kısa şekerlemeler',
      ],
      tips: [
        'Rutinleri sade tut.',
        'Uyaranı azalt.',
        'Gündüz uykularını kaçırmamaya çalış.',
      ],
    ),
    AttackModel(
      month: 5,
      windowStartDays: 7,
      windowEndDays: 10,
      title: '5. Ay Dönemi',
      description:
          'Hareketlenme artabilir; dönme/itme gibi beceriler uykuya yansıyabilir.',
      symptoms: [
        'Uyku pozisyonuyla uğraşma',
        'Uyku saatinde direnç',
        'Gündüz daha kısa uyku',
      ],
      tips: [
        'Yatmadan önce sakin geçiş.',
        'Gündüz enerji boşaltma (aşırıya kaçmadan).',
        'Uyku saati mümkün olduğunca sabit.',
      ],
    ),
    AttackModel(
      month: 6,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '6. Ay Dönemi',
      description:
          'Dikkat ve hareketlilik artar; uyku bölünmeleri görülebilir.',
      symptoms: [
        'Gece daha sık uyanma',
        'Sık kucak isteme',
        'Beslenme isteğinde artış',
        'Rutin dışı uyku saatleri',
      ],
      tips: [
        'Uykuya geçişte sakin mini ritüel.',
        'Uyku saatlerini mümkün olduğunca sabitle.',
        'Devam ederse tetikleyicileri gözle.',
      ],
    ),
    AttackModel(
      month: 7,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '7. Ay Dönemi',
      description:
          'Yeni beceriler ve çevre farkındalığı ile gece uyanmaları artabilir.',
      symptoms: [
        'Gece “kontrol uyanmaları”',
        'Uykuya dalmada uzama',
        'Gündüz daha seçici sakinleşme',
      ],
      tips: [
        'Gece müdahalelerini minimal tut.',
        'Gündüz rutinini koru.',
        'Uyku ortamını aynı tut.',
      ],
    ),
    AttackModel(
      month: 8,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '8. Ay Dönemi',
      description:
          'Ayrılma kaygısı başlayabilir; uyku öncesi itiraz artabilir.',
      symptoms: ['Ayrılmaya tepki', 'Uyku öncesi ağlama', 'Gece uyanmaları'],
      tips: [
        'Kısa, tekrarlı “güven sinyali” ver.',
        'Ce-ee gibi ayrılma oyunları.',
        'Uyaran/ekranı azalt.',
      ],
    ),
    AttackModel(
      month: 9,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '9. Ay Dönemi',
      description:
          'Hareket kabiliyeti artar; yatakta “pratik” yapma uykuyu bölebilir.',
      symptoms: [
        'Yatakta hareketlenme',
        'Uyku bölünmesi',
        'Gündüz uyku kısalması',
      ],
      tips: [
        'Gündüz motor aktivite fırsatı.',
        'Uyku öncesi daha sakin akış.',
        'Rutin stabil kalsın.',
      ],
    ),
    AttackModel(
      month: 10,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '10. Ay Dönemi',
      description:
          'Keşif artar; uyku saatinde direnç ve kısa uyanmalar olabilir.',
      symptoms: [
        'Uyku saatinde direnç',
        'Gece kısa uyanmalar',
        'Gündüz daha hareketli olma',
      ],
      tips: [
        'Enerji boşaltma fırsatı ver.',
        'Rutin aynı sırada kalsın.',
        'Uyku saatini çok kaydırma.',
      ],
    ),
    AttackModel(
      month: 11,
      windowStartDays: 10,
      windowEndDays: 14,
      title: '11. Ay Dönemi',
      description: 'Gündüz uyanıklık artar; daha fazla etkileşim isteyebilir.',
      symptoms: [
        'Daha “talepkâr” davranış',
        'Uykuya geçişte uzama',
        'Gündüz şekerlemelerinde azalma',
      ],
      tips: [
        'Yatmadan önce sakin oyun/kitap.',
        'Akşam rutini kısalt.',
        'Aşırı uyaranı azalt.',
      ],
    ),
    AttackModel(
      month: 12,
      windowStartDays: 12,
      windowEndDays: 16,
      title: '12. Ay Dönemi',
      description:
          'Dönüm noktası: motor ve sosyal gelişim artışı uyku/duygu dalgalanması yaratabilir.',
      symptoms: ['Gece uyanmaları', 'Rutin direnci', 'Duygu dalgalanmaları'],
      tips: [
        'Rutin stabil.',
        'Gündüz uyku saatini koru.',
        'Sakinleştirme yöntemini tutarlı yap.',
      ],
    ),

    // 13–18 ay: daha geniş pencere
    AttackModel(
      month: 13,
      windowStartDays: 14,
      windowEndDays: 18,
      title: '13. Ay Dönemi',
      description:
          'Yürüme/iletişim denemeleri artar; sınırları test etme başlayabilir.',
      symptoms: ['Uykuya direnç', 'Daha çok “hayır”', 'Ayrılmada zorlanma'],
      tips: [
        'Net ve sakin sınırlar.',
        'Uyku rutini aynı.',
        'Gündüz açık hava iyi gelir.',
      ],
    ),
    AttackModel(
      month: 14,
      windowStartDays: 14,
      windowEndDays: 18,
      title: '14. Ay Dönemi',
      description: 'Bağımsızlık isteği artar; kısa öfke anları görülebilir.',
      symptoms: ['Kısa öfke patlamaları', 'Uyku saatinde direnç', 'Seçicilik'],
      tips: [
        'Seçenek sun (2 seçenek).',
        'Geçişleri önceden haber ver.',
        'Kısa ve tutarlı rutin.',
      ],
    ),
    AttackModel(
      month: 15,
      windowStartDays: 14,
      windowEndDays: 18,
      title: '15. Ay Dönemi',
      description: 'Dil/iletişim denemeleri artarken frustrasyon yükselir.',
      symptoms: [
        'İstediğini anlatamama huzursuzluğu',
        'Uyku bölünmesi',
        'Ayrılmada zorlanma',
      ],
      tips: [
        'İşaret/kelimeyi destekle.',
        'Sakinleştirme aynı kalıp.',
        'Aşırı uyaranı azalt.',
      ],
    ),
    AttackModel(
      month: 16,
      windowStartDays: 16,
      windowEndDays: 20,
      title: '16. Ay Dönemi',
      description:
          'Rutinlere direnç artabilir; gece uyanmaları geçici artış gösterebilir.',
      symptoms: ['Gece uyanmaları', 'Uykuya geçiş uzaması', 'Gündüz huysuzluk'],
      tips: [
        'Gece müdahalesi minimal.',
        'Gündüz uyku kaçırma.',
        'Akşamı daha sakin kur.',
      ],
    ),
    AttackModel(
      month: 17,
      windowStartDays: 16,
      windowEndDays: 20,
      title: '17. Ay Dönemi',
      description:
          'Ayrılma kaygısı dalgalanabilir; uykuya yansıması sık görülür.',
      symptoms: [
        'Gece ebeveyn arama',
        'Uyku öncesi itiraz',
        'Gündüz daha yapışık olma',
      ],
      tips: [
        'Kısa ayrılık pratikleri.',
        'Uyku öncesi aynı mesaj.',
        'Güvenli rutin.',
      ],
    ),
    AttackModel(
      month: 18,
      windowStartDays: 16,
      windowEndDays: 20,
      title: '18. Ay Dönemi',
      description:
          'Bağımsızlık–yakınlık dengesi: inatlaşma ve uyku direnci görülebilir.',
      symptoms: ['Sınır testleri', 'Kısa öfke nöbetleri', 'Uyku direnci'],
      tips: [
        'Tutarlı sınırlar.',
        'Geçişleri yumuşat.',
        'Uyku rutinini “kısa ve net” tut.',
      ],
    ),

    // 19–24 ay: “toddler” pencereleri
    AttackModel(
      month: 19,
      windowStartDays: 18,
      windowEndDays: 22,
      title: '19. Ay Dönemi',
      description:
          'Duygu regülasyonu zorlayabilir; uyku ve iştah dalgalanabilir.',
      symptoms: ['Öfke anları', 'Uyku bölünmesi', 'Seçici yeme'],
      tips: [
        'Duyguyu adlandır.',
        'Rutin aynı.',
        'Gündüz hareket ve temiz hava.',
      ],
    ),
    AttackModel(
      month: 20,
      windowStartDays: 18,
      windowEndDays: 22,
      title: '20. Ay Dönemi',
      description:
          '“Ben yapacağım” dönemi; sınır ve kontrol ihtiyacı artabilir.',
      symptoms: ['İnatlaşma', 'Uyku saatinde pazarlık', 'Geçişlerde zorlanma'],
      tips: [
        'İki seçenek ver.',
        'Net sınır + sakin ton.',
        'Ödül/ceza yerine tutarlılık.',
      ],
    ),
    AttackModel(
      month: 21,
      windowStartDays: 18,
      windowEndDays: 22,
      title: '21. Ay Dönemi',
      description: 'Sosyal farkındalık artar; ayrılmalar yeniden zorlayabilir.',
      symptoms: [
        'Anne-baba yanında ister',
        'Uykuya geçiş uzaması',
        'Gece kontrol uyanmaları',
      ],
      tips: [
        'Ayrılık oyunları.',
        'Uyku öncesi sakin bağ.',
        'Gün içinde kısa kaliteli temas.',
      ],
    ),
    AttackModel(
      month: 22,
      windowStartDays: 18,
      windowEndDays: 22,
      title: '22. Ay Dönemi',
      description:
          'Dil artışıyla birlikte “hayır” dönemi; rutin direnci olabilir.',
      symptoms: ['Sık “hayır”', 'Uyku direnci', 'Duygu dalgalanması'],
      tips: [
        'Sınırlar net.',
        'Geçişleri önceden haber ver.',
        'Uyku öncesi ekranı azalt.',
      ],
    ),
    AttackModel(
      month: 23,
      windowStartDays: 18,
      windowEndDays: 22,
      title: '23. Ay Dönemi',
      description:
          'Kural/alışkanlık denemeleri; uyku ve davranış dalgalanabilir.',
      symptoms: [
        'Uyku saatinde itiraz',
        'Kısa öfke patlamaları',
        'Rutin değişimine hassasiyet',
      ],
      tips: [
        'Rutin stabil.',
        'Tepkiyi kısa tut.',
        'Sakinleştirici mini ritüel.',
      ],
    ),
    AttackModel(
      month: 24,
      windowStartDays: 20,
      windowEndDays: 24,
      title: '24. Ay Dönemi',
      description:
          '2 yaş geçişi: bağımsızlık, sınırlar ve duygu yoğunluğu artabilir.',
      symptoms: ['Öfke nöbetleri', 'Uyku direnci', 'Geçişlerde zorlanma'],
      tips: [
        'Önceden hazırlık (5 dk sonra...).',
        'Net ama sakin sınırlar.',
        'Uyku rutinini kısa tut.',
      ],
    ),
  ];

  static AttackModel? byMonth(int month) {
    for (final a in items) {
      if (a.month == month) return a;
    }
    return null;
  }
}
