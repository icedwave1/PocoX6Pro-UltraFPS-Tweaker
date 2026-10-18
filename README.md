# Poco X6 Pro 5G (duchamp) — Ultra FPS Tweaker v2.5 with KernelSU WebUI

Экстремальный твикер производительности, устранения микрофризов и стабилизации пинга, созданный специально для **Poco X6 Pro 5G** (`duchamp` / MediaTek Dimensity 8300-Ultra) под управлением прошивки **Pixel Experience / AOSP** с рутом **KernelSU** (также совместим с APatch и Magisk).

---

## 📥 Скачать готовый ZIP для прошивки
Готовые к установке архивы каждой версии автоматически выкладываются в раздел **GitHub Releases**:
👉 [**Скачать актуальный PocoX6Pro-UltraFPS-Tweaker.zip из Releases**](https://github.com/icedwave1/PocoX6Pro-UltraFPS-Tweaker/releases)

---

## 🔥 Ключевые возможности v2.5

### 1. Архитектурные твики MediaTek Dimensity 8300-Ultra (MT6897)
* **CPU Scheduler & MTK PPM (Processor Power Management)**:
  - Принудительное удержание всех 8 ядер (4x A510 + 3x A715 + 1x A715 Prime) в активном состоянии (`online=1`, отключение засыпания ядер в играх).
  - Принудительное выделение 100% мощности CPU для активного процесса (`top-app uclamp.min = 100%`, `latency_sensitive = 1`).
  - Минимизация задержек миграции потоков между кластерами и снижение латентности планировщика CFS.
* **MediaTek GED & FPSGO (Mali-G615 GPU Engine)**:
  - Форсирование игрового режима драйвера GPU (`gx_game_mode = 1`, `gx_force_cpu_boost = 1`).
  - Агрессивный DVFS margin — видеочип не сбрасывает частоты в тяжёлых сценах.
  - Автоматическая привязка PID запущенной игры к драйверу GED (`gx_top_app_pid`) и FPSGO.
* **MediaTek DVFSRC LPDDR5X DRAM Boost**:
  - Снятие лимитов с контроллера шины памяти для устранения микростаттеров при подгрузке тяжелых текстур.
* **Thermal Throttling Bypass**:
  - Отключение агрессивного троттлинга в температурных зонах ядра — стабильные частоты без просадок при длительных катках.

### 2. Экран, Тач & Задержки ввода
* **120Hz Force Lock (Pixel Experience)**:
  - Блокировка сброса герцовки до 60Hz при отсутствии касаний и в неоптимизированных играх.
  - Повышение приоритета `surfaceflinger` (nice -20) и привязка к производительным ядрам.
* **360Hz Touch Sampling**:
  - Геометрическая калибровка тача, уменьшение `touch_slop` для мгновенной реакции на микро-движения пальцев в шутерах.
* **Low-Latency Audio Pipeline**:
  - Уменьшение размера буфера вывода (`vendor.audio.offload.buffer.size.kb=32`) для мгновенного позиционирования звуков шагов.

### 3. Сеть, Пинг & Киберспорт (Esports Mode)
* **TCP BBR & Fast-Path**:
  - Активация алгоритма TCP BBR, отключение `notsent_lowat` bufferbloat для устранения сетевого джиттера.
  - Блокировка энергосбережения Wi-Fi чипа (`cmd wifi set-low-latency-mode enabled`).
* **Быстрый сброс DNS**:
  - Встроенный инструмент очистки кэшей резолвера прямо из WebUI.

### 4. Хранилище UFS 4.0 & Anti-Stutter
* **Zero-Lag ZRAM Engine**:
  - Настройка `page-cluster = 0` (устранение задержек декомпрессии страниц zRAM).
  - Оптимизация очередей UFS 4.0 (`read_ahead_kb = 1024`, `rq_affinity = 2`).
  - Отключение фонового ядра трейсинга `ftrace` и ограничение буфера логов `logd`.

---

## 💻 Полнофункциональный WebUI в KernelSU

Модуль включает встроенный веб-интерфейс в стиле Cyberpunk / Dark OLED, доступный прямо из приложения **KernelSU Manager**:

1. **Главный переключатель**: Включение / Выключение всех твиков одним тапом.
2. **5 готовых профилей в 1 клик**:
   - 🚀 **EXTREME**: Полный разгон ядер и GPU, DVFSRC, анти-троттлинг, 120Hz lock, максимальный FPS.
   - 🎯 **ESPORTS**: Минимальный пинг (TCP BBR + Low-Latency Wi-Fi), отклик тача 360Hz, 120Hz lock.
   - ⚡ **BALANCED**: Высокая плавность 120Hz без перегрева аккумулятора.
   - 🔋 **BATTERY**: Энергосбережение и холод для повседневных задач.
   - 🔄 **STOCK**: Полный откат к заводским настройкам AOSP.
3. **Мониторинг железа в реальном времени**:
   - Температуры CPU и аккумулятора + ток разряда (mA).
   - Частоты всех 8 ядер (cpu0..cpu7) отдельно с цветовой индикацией кластеров.
   - Свободная память ОЗУ, ZRAM, активный говернор и TCP алгоритм.
4. **Быстрые действия (Quick Actions)**:
   - 🎯 **Boost активной игры (PID Realtime)**: находит игру на экране, ставит `nice -20`, `ionice realtime`, защиту `oom_score_adj -900`, закрепляет за ядрами A715 и прописывает в MTK GED.
   - 🧹 **Очистить RAM и кэш**: сброс кэшей (`drop_caches`) и компактизация памяти.
   - 📶 **Сброс DNS & Ping Boost**: очистка DNS резолверов и форсирование Low Latency Wi-Fi.
   - 📋 **Консоль логов**: вывод команд в реальном времени.

---

## 📦 Установка

### Способ 1: Через приложение KernelSU Manager (на телефоне)
1. Скачайте [**`PocoX6Pro-UltraFPS-Tweaker.zip`**](https://github.com/icedwave1/PocoX6Pro-UltraFPS-Tweaker/releases) на телефон.
2. Откройте приложение **KernelSU**.
3. Перейдите во вкладку **«Модули»** -> нажмите **«Установить»**.
4. Выберите архив `PocoX6Pro-UltraFPS-Tweaker.zip`.
5. После установки откройте WebUI прямо из списка модулей!

### Способ 2: Через ADB (с компьютера)
```bash
adb push PocoX6Pro-UltraFPS-Tweaker.zip /sdcard/
# Установка через ksud (если установлен):
adb shell su -c "ksud module install /sdcard/PocoX6Pro-UltraFPS-Tweaker.zip"
```

---

## 🕹 Быстрое переключение без входа в WebUI (Action Button)
В приложении KernelSU напротив модуля есть кнопка **«Действие» (Action)**:
- Тап по ней мгновенно переключает режим между **EXTREME GAMING** и **STOCK**.

---

## 👥 Contributors

* **Antigravity**
* **Claude**
