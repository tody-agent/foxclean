# FoxClean

FoxClean هو تطبيق مجاني ومفتوح المصدر لتنظيف macOS وتحسينه. يجمع بين تطبيق
SwiftUI أصلي، ونواة Swift مشتركة، وأداة سطر الأوامر `fox`.

## البدء السريع

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## الميزات

- التطبيق و CLI يستخدمان `FoxCleanCore` نفسه.
- العمليات الخطرة تعمل dry-run افتراضيا، وبعد التأكيد يتم النقل إلى Trash أولا.
- سجل العمليات بصيغة JSONL ويدعم rollback.
- يتضمن فحص التطبيقات، تنظيف الملفات غير الضرورية، اكتشاف orphan files، تحليل القرص،
  حالة النظام، تنظيف ملفات التثبيت، project purge، مهام التحسين، shell completion،
  و quick launcher scripts.
- بدون telemetry، بدون subscription، وبترخيص MIT.

## ملاحظة الإصدار

النشر العام ما زال يحتاج Developer ID signing و notarization وصلاحيات نشر للمستودع
أو مدير الحزم.
