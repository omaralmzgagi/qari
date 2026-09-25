import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/files/data/services/script_language_detector.dart';
import 'package:qari/features/files/domain/language/detected_language.dart';

void main() {
  const detector = ScriptLanguageDetector();

  String detect(String text) => detector.detect(text).code;

  group('script based detection', () {
    test('Arabic text from a real passage is detected as ar', () {
      const text = 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين '
          'إياك نعبد وإياك نستعين';
      final result = detector.detect(text);
      expect(result.code, 'ar');
      expect(result.confidence, greaterThanOrEqualTo(0.6));
    });

    test('Arabic sentence with Latin loanwords stays ar', () {
      const text = 'تم تحديث البرنامج اليوم وإضافة ميزة PDF جديدة للقراءة';
      expect(detect(text), 'ar');
    });

    test('Chinese characters are detected as zh', () {
      const text = '今天天气很好我们一起去公园散步读书学习中文';
      expect(detect(text), 'zh');
    });

    test('Devanagari characters are detected as hi', () {
      const text = 'हिंदी भाषा बहुत सुंदर है और हम रोज पढ़ते हैं';
      expect(detect(text), 'hi');
    });
  });

  group('latin stop-word detection', () {
    test('English is detected as en', () {
      const text =
          'The quick brown fox jumps over the lazy dog and the cat sat '
          'on the mat because it was warm.';
      expect(detect(text), 'en');
    });

    test('French is detected as fr', () {
      const text = 'Le chat est sur le tapis et la souris dort dans la maison '
          'pendant que les enfants jouent dehors.';
      expect(detect(text), 'fr');
    });

    test('Spanish is detected as es', () {
      const text = 'El gato está sobre el tapiz y la rama cae del árbol porque '
          'el viento sopla fuerte en la tarde.';
      expect(detect(text), 'es');
    });

    test('German is detected as de', () {
      const text =
          'Der Hund liegt auf dem Sofa und die Katze schläft im Garten '
          'während die Kinder draußen spielen.';
      expect(detect(text), 'de');
    });

    test('Turkish is detected as tr', () {
      const text =
          'Bu bir test cümlesi ve çok güzel görünüyor ama hala bitmedi '
          'çünkü kitap okumaya devam ediyorum.';
      expect(detect(text), 'tr');
    });

    test('Italian is detected as it', () {
      const text = 'Il libro è sulla scrivania e la penna non funziona più '
          'perché il bambino l’ha lasciato fuori.';
      expect(detect(text), 'it');
    });

    test('Portuguese is detected as pt', () {
      const text = 'O livro está na mesa e o café não está bom porque o tempo '
          'mudou muito rápido hoje de manhã.';
      expect(detect(text), 'pt');
    });
  });

  group('unreliable input', () {
    test('very short text returns unknown', () {
      expect(detector.detect('ok').code, DetectedLanguage.unknownCode);
      expect(detector.detect('').code, DetectedLanguage.unknownCode);
      expect(detector.detect('   ').code, DetectedLanguage.unknownCode);
    });

    test('text without letters returns unknown', () {
      expect(detect('12345 !!! --- 67890'), DetectedLanguage.unknownCode);
    });

    test('a low confidence guess is not promoted to a language', () {
      final result = detector.detect('x y z q w');
      expect(result.code, DetectedLanguage.unknownCode);
    });
  });

  group('contract', () {
    test('supported codes cover the ten languages required by the brief', () {
      expect(
        DetectedLanguage.supportedCodes,
        ['ar', 'en', 'fr', 'es', 'de', 'tr', 'it', 'pt', 'zh', 'hi'],
      );
    });

    test('the detector never throws on arbitrary input', () {
      const samples = [
        '',
        '   ',
        '\u0000\u0001\u0002',
        '!!! ??? ...',
        'null; drop table users; --',
        'ek af nam',
        'x y z q w',
      ];
      for (final sample in samples) {
        expect(
          () => detector.detect(sample),
          returnsNormally,
          reason: 'detection must not throw for: $sample',
        );
      }
    });
  });
}
