# Sibvaleo — контекст проекта

## Что это
Flutter-приложение для Windows. Инструмент консультанта Siberian Wellness:
подбирает продуктовые программы под жалобы клиента, экспортирует в HTML/PDF.

## Пути
- Исходник: `C:\Projects\sibvaleo` (путь БЕЗ кириллицы — обязательно)
- Оригинал: `C:\Users\HP\Проекты\sibvaleo` (не использовать для сборки — ломает MSBuild)
- Репозиторий: https://github.com/Oleg5603/sibvaleo.git
- Готовый билд: `C:\Users\HP\Desktop\Sibvaleo\sibvaleo.exe`

## Сборка
```
cd C:\Projects\sibvaleo
C:\flutter\bin\flutter.bat build windows --release
```
Результат: `build\windows\x64\runner\Release\`
После сборки скопировать всё из Release в `C:\Users\HP\Desktop\Sibvaleo\`

## Flutter
- Установлен в `C:\flutter\bin\` (в PATH не добавлен — вызывать полным путём)
- SDK: Dart >=3.0.0 <4.0.0
- Зависимости: только flutter SDK, сторонних пакетов нет

## Архитектура
```
lib/
├── main.dart                          — точка входа, загрузка данных, проверка триала
├── models/
│   ├── product.dart                   — модель продукта (категория, жалобы, синергия)
│   └── client.dart                    — модель клиента (жалобы, стадия, оценка)
├── data/
│   ├── recommendation_engine.dart     — движок подбора программ
│   └── app_storage.dart               — хранилище клиентов (JSON файлы локально)
├── screens/
│   ├── home_screen.dart               — список клиентов, главный экран
│   ├── client_form_screen.dart        — анкета клиента (жалобы, стадия здоровья)
│   ├── product_selection_screen.dart  — подбор продуктов (самый большой экран, 1043 стр)
│   ├── program_view_screen.dart       — итоговая программа клиента
│   ├── catalog_screen.dart            — каталог всех продуктов
│   ├── code_generator_screen.dart     — генератор кодов активации для консультанта
│   └── trial_expired_screen.dart      — экран истечения пробного периода
└── utils/
    ├── trial.dart                     — триальная система
    ├── activation.dart                — коды активации SVLnnn-mmmmm
    ├── html_export.dart               — экспорт программы в HTML
    └── pdf_export.dart                — экспорт в PDF
assets/
├── data/products.json                 — база продуктов Siberian Wellness
└── data/conditions.json               — база жалоб/состояний
```

## Система активации
Формат: `SVLnnn-mmmmm` (пример: `SVL001-62277`)
- `nnn` — номер клиента 001–999
- `mmmmm` — чексумма: `(n × 37 + slot × 7919 + 54321) % 100000`
- slot 1 = ПК, slot 2 = телефон
- На клиента генерируется пара кодов (экран `code_generator_screen.dart`)
- Код сохраняется в `%LOCALAPPDATA%\sibvaleo\trial.json`

## Триал
- 4 дня с первого запуска (`kTrialDays = 4` в `trial.dart`)
- Хранится: `%LOCALAPPDATA%\sibvaleo\trial.json`
- По истечении показывает `TrialExpiredScreen`

## Данные клиентов
- Хранятся локально в JSON через `app_storage.dart`
- Путь хранилища: `%LOCALAPPDATA%\sibvaleo\`

## Экспорт
- HTML: `html_export.dart` — кодировка UTF-8, русские имена, кнопки печати
- PDF: `pdf_export.dart`
- В `program_view_screen.dart` — bottom sheet с 3 вариантами (сохранить / печать / PDF)

## Известные ограничения
- MSBuild не работает с кириллицей в пути → всегда собирать из `C:\Projects\sibvaleo`
- `flutter` не в системном PATH → вызывать как `C:\flutter\bin\flutter.bat`

## Git
- Ветка: `master`
- `build/` в `.gitignore` — билд не коммитится
- Коммитить только изменения в `lib/`, `assets/`, `pubspec.yaml`
