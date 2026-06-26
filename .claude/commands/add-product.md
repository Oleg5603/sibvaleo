# /add-product

Добавляет новый препарат Siberian Wellness в базу данных.

## Использование
```
/add-product [название препарата]
```

## Что делает
1. Запрашивает информацию о препарате (или парсит из текста)
2. Формирует JSON-запись в формате `assets/data/products.json`
3. Добавляет запись в файл
4. Коммитит изменение

## Формат записи (все поля обязательны)
```json
{
  "id": "уникальный_id_латиница",
  "name": "Название препарата",
  "series": "Серия (Essential Vitamins / ЭПАМ / etc)",
  "form": "капсулы / капли / таблетки / порошок",
  "category": "Категория",
  "stage": 1,
  "stage_name": "ОЧИЩЕНИЕ / ЗАЩИТА / ПИТАНИЕ / ВОССТАНОВЛЕНИЕ",
  "composition": "Состав...",
  "action": "Действие...",
  "indications": ["condition_id_1", "condition_id_2"],
  "symptoms": ["symptom_id_1"],
  "contraindications": ["противопоказание"],
  "dose_adult": "Доза взрослым",
  "dose_child_6_12": null,
  "dose_child_12_18": null,
  "dose_elderly": null,
  "dose_intensive": null,
  "frequency_per_day": 1,
  "min_course_days": 30,
  "max_course_days": 60,
  "notes": "Заметки по применению"
}
```

## Этапы (stage)
- 1 ОЧИЩЕНИЕ — сорбенты, детокс, дренаж органов
- 2 ЗАЩИТА — иммунитет, антиоксиданты, противовирусные
- 3 ПИТАНИЕ — витамины, минералы, омега, ВМК
- 4 ВОССТАНОВЛЕНИЕ — органо-специфические (ЖКТ, сердце, суставы, нервы)

## Доступные condition IDs (из conditions.json)
Симптомы: частые_простуды, слабость, боли_в_суставах, боли_в_спине, изжога, вздутие_живота, запоры, диарея, боль_в_желудке, тошнота, боли_в_правом_боку, горечь_во_рту, желтушность, боли_в_сердце, аритмия, повышенное_давление, одышка, тревога, бессонница, снижение_памяти, головные_боли, депрессия, выпадение_волос, ломкость_ногтей, акне, сухость_кожи, морщины, набор_веса, зябкость, увеличение_щитовидной, болезненные_месячные, нерегулярный_цикл, симптомы_менопаузы, цистит, боли_в_пояснице_почки, кашель, насморк, аллергия, интоксикация, после_антибиотиков, после_COVID

Диагнозы: gastritis, gastric_ulcer, colitis, irritable_bowel, gut_dysbiosis, hepatitis, fatty_liver, cholecystitis, hypertension, atherosclerosis, arrhythmia, osteoarthritis, rheumatoid_arthritis, osteochondrosis, osteoporosis, depression, insomnia, hypothyroidism, endemic_goiter, pms, endometriosis, menopause, cystitis, prostatitis, iron_deficiency_anemia, diabetes_2, obesity, bronchitis, asthma
