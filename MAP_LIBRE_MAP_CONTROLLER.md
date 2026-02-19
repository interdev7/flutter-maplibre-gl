# MapLibreMapController — Полная документация

> Контроллер для одного экземпляра `MapLibreMap`. Некоторые методы можно вызывать **только после** срабатывания коллбэка `onStyleLoaded`.

---

## Содержание

1. [Получение контроллера](#1-получение-контроллера)
2. [Камера](#2-камера)
3. [GeoJSON источники (Sources)](#3-geojson-источники-sources) ⭐
4. [Остальные источники (Sources)](#4-остальные-источники-sources)
5. [Слои (Layers)](#5-слои-layers)
6. [Символы (Symbols)](#6-символы-symbols)
7. [Линии (Lines)](#7-линии-lines)
8. [Круги (Circles)](#8-круги-circles)
9. [Заливки (Fills)](#9-заливки-fills)
10. [Изображения](#10-изображения)
11. [Запросы (Query)](#11-запросы-query)
12. [Координаты и экран](#12-координаты-и-экран)
13. [Стиль и язык](#13-стиль-и-язык)
14. [Настройки символов](#14-настройки-символов)
15. [Кэш и телеметрия](#15-кэш-и-телеметрия)
16. [Свойства и коллбэки](#16-свойства-и-коллбэки)

---

## 1. Получение контроллера

```dart
class MyMapPage extends StatefulWidget {
  @override
  State<MyMapPage> createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: 'https://demotiles.maplibre.org/style.json',
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.8939, 58.3755),
        zoom: 12,
      ),
      onMapCreated: (controller) {
        _controller = controller;
      },
      onStyleLoadedCallback: () {
        // Стиль загружен — теперь можно вызывать методы контроллера
        _addDataToMap();
      },
    );
  }

  void _addDataToMap() {
    // Здесь безопасно работать с _controller
  }
}
```

> **Важно:** Используйте `Completer<MapLibreMapController>` если нужно дождаться контроллера в async-коде:
>
> ```dart
> final _completer = Completer<MapLibreMapController>();
> // в onMapCreated: _completer.complete(controller);
> // в другом месте: final c = await _completer.future;
> ```

---

## 2. Камера

### `animateCamera`

Плавно перемещает камеру к новой позиции с анимацией.

```dart
Future<bool?> animateCamera(CameraUpdate cameraUpdate, {Duration? duration})
```

```dart
// Переместить к точке
await controller.animateCamera(
  CameraUpdate.newLatLng(LatLng(37.89, 58.37)),
  duration: Duration(milliseconds: 1500),
);

// Переместить с зумом
await controller.animateCamera(
  CameraUpdate.newLatLngZoom(LatLng(37.89, 58.37), 15.0),
);

// Приблизить
await controller.animateCamera(CameraUpdate.zoomIn());

// Отдалить
await controller.animateCamera(CameraUpdate.zoomOut());

// Установить конкретный зум
await controller.animateCamera(CameraUpdate.zoomTo(10.0));

// Камера с наклоном и поворотом
await controller.animateCamera(
  CameraUpdate.newCameraPosition(
    CameraPosition(
      target: LatLng(37.89, 58.37),
      zoom: 15,
      bearing: 45.0,   // поворот в градусах
      tilt: 60.0,       // наклон в градусах
    ),
  ),
);

// Вместить область в экран
await controller.animateCamera(
  CameraUpdate.newLatLngBounds(
    LatLngBounds(
      southwest: LatLng(37.80, 58.30),
      northeast: LatLng(37.95, 58.45),
    ),
    left: 50, top: 50, right: 50, bottom: 50, // padding
  ),
);
```

---

### `moveCamera`

Мгновенно перемещает камеру (без анимации). Принимает те же `CameraUpdate` что и `animateCamera`.

```dart
Future<bool?> moveCamera(CameraUpdate cameraUpdate)
```

```dart
await controller.moveCamera(
  CameraUpdate.newLatLngZoom(LatLng(37.89, 58.37), 14.0),
);
```

---

### `easeCamera`

Плавно перемещает камеру c «замедлением» (easing). Похоже на `animateCamera`, но с другой кривой анимации.

```dart
Future<bool> easeCamera(CameraUpdate cameraUpdate, {Duration? duration})
```

```dart
await controller.easeCamera(
  CameraUpdate.newLatLngZoom(LatLng(37.89, 58.37), 16.0),
  duration: Duration(seconds: 2),
);
```

---

### `queryCameraPosition`

Возвращает текущую позицию камеры (center, zoom, bearing, tilt).

```dart
Future<CameraPosition?> queryCameraPosition()
```

```dart
final pos = await controller.queryCameraPosition();
print('Центр: ${pos?.target}, Зум: ${pos?.zoom}');
```

---

### `setCameraBounds`

Ограничивает видимую область карты заданными координатами.

```dart
Future setCameraBounds({
  required double west,
  required double north,
  required double south,
  required double east,
  required int padding,
})
```

```dart
await controller.setCameraBounds(
  west: 58.30,
  east: 58.45,
  south: 37.80,
  north: 37.95,
  padding: 20,
);
```

---

### `getVisibleRegion`

Возвращает границы текущей видимой области карты.

```dart
Future<LatLngBounds> getVisibleRegion()
```

```dart
final bounds = await controller.getVisibleRegion();
print('SW: ${bounds.southwest}, NE: ${bounds.northeast}');
```

---

## 3. GeoJSON источники (Sources) ⭐

> Это **продвинутый способ** работы с картой. Вы добавляете данные как **GeoJSON source**, затем создаёте **layer** для визуализации этих данных.

### `addGeoJsonSource`

Добавляет новый GeoJSON источник данных на карту.

```dart
Future<void> addGeoJsonSource(
  String sourceId,
  Map<String, dynamic> geojson,
  {String? promoteId}
)
```

**Параметры:**
| Параметр | Тип | Описание |
|---|---|---|
| `sourceId` | `String` | Уникальный ID источника |
| `geojson` | `Map<String, dynamic>` | GeoJSON FeatureCollection (по [RFC 7946](https://datatracker.ietf.org/doc/html/rfc7946#section-3.3)) |
| `promoteId` | `String?` | (Web) Имя свойства, которое станет ID фичи |

---

#### Пример 1: Точки на карте (маркеры через circle layer)

```dart
void _addPointsSource() async {
  // 1. Добавляем GeoJSON source с точками
  await controller.addGeoJsonSource('points-source', {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'id': 1,
        'geometry': {
          'type': 'Point',
          'coordinates': [58.3755, 37.8939], // [lng, lat] !
        },
        'properties': {
          'name': 'Ашхабад',
          'category': 'city',
        },
      },
      {
        'type': 'Feature',
        'id': 2,
        'geometry': {
          'type': 'Point',
          'coordinates': [59.5567, 36.2960],
        },
        'properties': {
          'name': 'Мешхед',
          'category': 'city',
        },
      },
    ],
  });

  // 2. Добавляем circle layer для визуализации точек
  await controller.addCircleLayer(
    'points-source',    // sourceId
    'points-layer',     // layerId
    CircleLayerProperties(
      circleRadius: 8,
      circleColor: '#FF5722',
      circleStrokeWidth: 2,
      circleStrokeColor: '#FFFFFF',
    ),
  );
}
```

---

#### Пример 2: Точки с иконками (symbol layer)

```dart
void _addIconPoints() async {
  // 1. Загружаем изображение для иконки
  final bytes = await rootBundle.load('assets/marker.png');
  await controller.addImage('my-marker', bytes.buffer.asUint8List());

  // 2. Добавляем GeoJSON source
  await controller.addGeoJsonSource('icons-source', {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [58.3755, 37.8939],
        },
        'properties': {
          'title': 'Маркер 1',
          'icon': 'my-marker',
        },
      },
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [59.5567, 36.2960],
        },
        'properties': {
          'title': 'Маркер 2',
          'icon': 'my-marker',
        },
      },
    ],
  });

  // 3. Добавляем symbol layer
  await controller.addSymbolLayer(
    'icons-source',
    'icons-layer',
    SymbolLayerProperties(
      iconImage: ['get', 'icon'],       // берём значение из properties.icon
      iconSize: 0.15,
      iconAnchor: 'bottom',            // center, top, bottom, left, right
      textField: ['get', 'title'],      // берём значение из properties.title
      textOffset: [
        Expressions.literal, [0, 1.2]
      ],
      textSize: 12,
      textColor: '#333333',
      textHaloColor: '#FFFFFF',
      textHaloWidth: 1,
    ),
  );
}
```

---

#### Пример 3: Линии (маршрут)

```dart
void _addRoute() async {
  await controller.addGeoJsonSource('route-source', {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [58.3755, 37.8939],
            [58.3800, 37.8980],
            [58.3850, 37.9020],
            [58.3900, 37.9050],
          ],
        },
        'properties': {
          'name': 'Маршрут А',
          'color': '#2196F3',
        },
      },
    ],
  });

  await controller.addLineLayer(
    'route-source',
    'route-layer',
    LineLayerProperties(
      lineColor: ['get', 'color'],
      lineWidth: 4,
      lineCap: 'round',
      lineJoin: 'round',
    ),
  );
}
```

---

#### Пример 4: Полигоны (области / зоны)

```dart
void _addZones() async {
  await controller.addGeoJsonSource('zones-source', {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [58.35, 37.88],
              [58.40, 37.88],
              [58.40, 37.92],
              [58.35, 37.92],
              [58.35, 37.88], // замыкаем полигон
            ]
          ],
        },
        'properties': {
          'name': 'Зона А',
          'risk': 'high',
        },
      },
    ],
  });

  // Заливка
  await controller.addFillLayer(
    'zones-source',
    'zones-fill-layer',
    FillLayerProperties(
      fillColor: '#FF5722',
      fillOpacity: 0.3,
    ),
  );

  // Обводка
  await controller.addLineLayer(
    'zones-source',
    'zones-outline-layer',
    LineLayerProperties(
      lineColor: '#FF5722',
      lineWidth: 2,
    ),
  );
}
```

---

#### Пример 5: Стилизация по свойствам (data-driven styling)

```dart
void _addDataDrivenPoints() async {
  await controller.addGeoJsonSource('dd-source', {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {'type': 'Point', 'coordinates': [58.37, 37.89]},
        'properties': {'magnitude': 2.5, 'type': 'earthquake'},
      },
      {
        'type': 'Feature',
        'geometry': {'type': 'Point', 'coordinates': [58.39, 37.91]},
        'properties': {'magnitude': 5.0, 'type': 'earthquake'},
      },
      {
        'type': 'Feature',
        'geometry': {'type': 'Point', 'coordinates': [58.36, 37.87]},
        'properties': {'magnitude': 7.5, 'type': 'earthquake'},
      },
    ],
  });

  await controller.addCircleLayer(
    'dd-source',
    'dd-layer',
    CircleLayerProperties(
      // Радиус зависит от magnitude
      circleRadius: [
        'interpolate', ['linear'],
        ['get', 'magnitude'],
        1, 4,     // magnitude 1 → радиус 4px
        5, 15,    // magnitude 5 → радиус 15px
        10, 30,   // magnitude 10 → радиус 30px
      ],
      // Цвет зависит от magnitude
      circleColor: [
        'interpolate', ['linear'],
        ['get', 'magnitude'],
        1, '#00FF00',   // зелёный
        5, '#FFFF00',   // жёлтый
        10, '#FF0000',  // красный
      ],
      circleOpacity: 0.7,
      circleStrokeWidth: 1,
      circleStrokeColor: '#FFFFFF',
    ),
  );
}
```

---

#### Пример 6: Фильтрация фич

```dart
// Показать только фичи с category == 'city'
await controller.addCircleLayer(
  'points-source',
  'filtered-layer',
  CircleLayerProperties(circleRadius: 6, circleColor: '#2196F3'),
  filter: ['==', ['get', 'category'], 'city'],
);

// Показать точки с population > 100000
await controller.addCircleLayer(
  'points-source',
  'big-cities-layer',
  CircleLayerProperties(circleRadius: 10, circleColor: '#E91E63'),
  filter: ['>', ['get', 'population'], 100000],
);
```

---

#### Пример 7: Heatmap (тепловая карта)

```dart
void _addHeatmap() async {
  await controller.addGeoJsonSource('heat-source', {
    'type': 'FeatureCollection',
    'features': List.generate(100, (i) => {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [58.35 + (i % 10) * 0.01, 37.85 + (i ~/ 10) * 0.01],
      },
      'properties': {'weight': (i % 5) + 1},
    }),
  });

  await controller.addHeatmapLayer(
    'heat-source',
    'heat-layer',
    HeatmapLayerProperties(
      heatmapWeight: ['get', 'weight'],
      heatmapIntensity: [
        'interpolate', ['linear'], ['zoom'],
        0, 1,
        9, 3,
      ],
      heatmapRadius: [
        'interpolate', ['linear'], ['zoom'],
        0, 2,
        9, 20,
      ],
    ),
    maxzoom: 15,
  );
}
```

---

### `setGeoJsonSource`

Обновляет данные **существующего** GeoJSON источника полностью (заменяет весь FeatureCollection).

```dart
Future<void> setGeoJsonSource(String sourceId, Map<String, dynamic> geojson)
```

```dart
// Обновить все данные источника
await controller.setGeoJsonSource('points-source', {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'id': 1,
      'geometry': {
        'type': 'Point',
        'coordinates': [58.40, 37.90], // обновлённые координаты
      },
      'properties': {'name': 'Обновлённая точка'},
    },
  ],
});
```

---

### `setGeoJsonFeature`

Обновляет **одну фичу** в существующем источнике (по ID фичи).

```dart
Future<void> setGeoJsonFeature(String sourceId, Map<String, dynamic> geojsonFeature)
```

```dart
await controller.setGeoJsonFeature('points-source', {
  'type': 'Feature',
  'id': 1,   // ID фичи для обновления
  'geometry': {
    'type': 'Point',
    'coordinates': [58.42, 37.92],
  },
  'properties': {'name': 'Перемещённая точка'},
});
```

---

### `editGeoJsonSource`

Обновляет GeoJSON источник, принимая данные как **строку JSON**.

```dart
Future<bool> editGeoJsonSource(String id, String data)
```

```dart
import 'dart:convert';

final geojson = jsonEncode({
  'type': 'FeatureCollection',
  'features': [/* ... */],
});
final success = await controller.editGeoJsonSource('my-source', geojson);
```

---

### `editGeoJsonUrl`

Обновляет GeoJSON источник, указывая **URL** для загрузки данных.

```dart
Future<bool> editGeoJsonUrl(String id, String url)
```

```dart
await controller.editGeoJsonUrl(
  'my-source',
  'https://example.com/data.geojson',
);
```

---

### `removeSource`

Удаляет ранее добавленный источник по ID.

```dart
Future<void> removeSource(String sourceId)
```

```dart
// Сначала удалите все слои, которые используют этот source!
await controller.removeLayer('points-layer');
await controller.removeSource('points-source');
```

---

### `addSource`

Добавляет источник любого типа (vector, raster, raster-dem и т.д.).

```dart
Future<void> addSource(String sourceId, SourceProperties properties)
```

```dart
// Vector tile source
await controller.addSource(
  'openmaptiles',
  VectorSourceProperties(url: 'https://example.com/tiles.json'),
);

// Raster tile source
await controller.addSource(
  'satellite',
  RasterSourceProperties(
    tiles: ['https://tile.example.com/{z}/{x}/{y}.png'],
    tileSize: 256,
  ),
);

// GeoJSON source (альтернатива addGeoJsonSource)
await controller.addSource(
  'my-geojson',
  GeojsonSourceProperties(data: 'https://example.com/data.geojson'),
);
```

---

### `getSourceIds`

Возвращает список ID всех источников на карте.

```dart
Future<List<String>> getSourceIds()
```

```dart
final ids = await controller.getSourceIds();
print('Sources: $ids'); // [openmaptiles, points-source, ...]
```

---

## 4. Остальные источники (Sources)

### `addImageSource` / `updateImageSource`

Добавляет/обновляет изображение как источник на карте (не web).

```dart
Future<void> addImageSource(String imageSourceId, Uint8List bytes, LatLngQuad coordinates)
Future<void> updateImageSource(String imageSourceId, Uint8List? bytes, LatLngQuad? coordinates)
```

```dart
final bytes = (await rootBundle.load('assets/overlay.png')).buffer.asUint8List();

await controller.addImageSource(
  'overlay-source',
  bytes,
  LatLngQuad(
    topLeft: LatLng(37.95, 58.30),
    topRight: LatLng(37.95, 58.45),
    bottomRight: LatLng(37.85, 58.45),
    bottomLeft: LatLng(37.85, 58.30),
  ),
);

await controller.addImageLayer('overlay-layer', 'overlay-source');
```

---

## 5. Слои (Layers)

### `addLayer` — универсальный метод

Автоматически определяет тип `LayerProperties` и вызывает нужный специфичный метод.

```dart
Future<void> addLayer(
  String sourceId,
  String layerId,
  LayerProperties properties, {
  String? belowLayerId,
  bool enableInteraction = true,
  String? sourceLayer,
  double? minzoom,
  double? maxzoom,
  dynamic filter,
})
```

Поддерживаемые типы: `FillLayerProperties`, `FillExtrusionLayerProperties`, `LineLayerProperties`, `SymbolLayerProperties`, `CircleLayerProperties`, `RasterLayerProperties`, `HillshadeLayerProperties`, `HeatmapLayerProperties`.

```dart
await controller.addLayer(
  'my-source',
  'my-circle-layer',
  CircleLayerProperties(circleRadius: 5, circleColor: '#FF0000'),
  minzoom: 5,
  maxzoom: 18,
  enableInteraction: true,
);
```

---

### Специфичные методы добавления слоёв

Все имеют одинаковую сигнатуру:

```dart
Future<void> add___Layer(
  String sourceId,
  String layerId,
  ___LayerProperties properties, {
  String? belowLayerId,    // вставить ПОД этим слоем
  String? sourceLayer,     // для vector tile sources
  double? minzoom,         // мин. зум видимости (включительно)
  double? maxzoom,         // макс. зум видимости (исключительно)
  dynamic filter,          // expression фильтр
  bool enableInteraction = true,  // обрабатывать тапы (не для raster/hillshade)
})
```

| Метод                   | LayerProperties                | Описание           |
| ----------------------- | ------------------------------ | ------------------ |
| `addSymbolLayer`        | `SymbolLayerProperties`        | Иконки и текст     |
| `addLineLayer`          | `LineLayerProperties`          | Линии              |
| `addFillLayer`          | `FillLayerProperties`          | Заливки полигонов  |
| `addFillExtrusionLayer` | `FillExtrusionLayerProperties` | 3D экструзии       |
| `addCircleLayer`        | `CircleLayerProperties`        | Круги              |
| `addRasterLayer`        | `RasterLayerProperties`        | Растровые тайлы    |
| `addHillshadeLayer`     | `HillshadeLayerProperties`     | Рельеф (hillshade) |
| `addHeatmapLayer`       | `HeatmapLayerProperties`       | Тепловая карта     |

---

### `addImageLayer` / `addImageLayerBelow`

Добавляет слой для отображения `ImageSource`.

```dart
await controller.addImageLayer('overlay-layer', 'overlay-source');
await controller.addImageLayerBelow('overlay-layer', 'labels', 'overlay-source');
```

---

### `removeLayer`

```dart
await controller.removeLayer('my-layer');
```

### `setLayerVisibility`

```dart
await controller.setLayerVisibility('my-layer', false); // скрыть
await controller.setLayerVisibility('my-layer', true);  // показать
```

### `setLayerProperties`

Обновляет свойства существующего слоя.

```dart
await controller.setLayerProperties(
  'my-circle-layer',
  CircleLayerProperties(circleColor: '#00FF00', circleRadius: 12),
);
```

> ⚠️ `null`-значения **не пропускаются** — они сбросят свойство к значению по умолчанию.

### `setFilter` / `getFilter`

```dart
await controller.setFilter('my-layer', ['==', ['get', 'type'], 'restaurant']);
final filter = await controller.getFilter('my-layer');
```

### `setLayerFilter`

Альтернативный метод — принимает фильтр как **JSON строку**.

```dart
await controller.setLayerFilter('my-layer', '["==", ["get", "type"], "city"]');
```

### `getLayerIds`

```dart
final layers = await controller.getLayerIds();
```

---

## 6. Символы (Symbols)

> «Простой» способ: управление аннотациями через менеджер. Не требует создания source/layer вручную.

### `addSymbol`

```dart
Future<Symbol> addSymbol(SymbolOptions options, [Map? data])
```

```dart
final symbol = await controller.addSymbol(
  SymbolOptions(
    geometry: LatLng(37.89, 58.37),
    iconImage: 'my-marker',        // добавьте через addImage
    iconSize: 0.15,
    iconAnchor: 'bottom',          // center, top, bottom, left, right,
                                   // top-left, top-right, bottom-left, bottom-right
    textField: 'Привет!',
    textOffset: Offset(0, 1.5),
    textColor: '#333333',
    draggable: false,
  ),
  {'id': 'marker-1'},  // пользовательские данные
);
```

### `addSymbols`

```dart
final symbols = await controller.addSymbols([
  SymbolOptions(geometry: LatLng(37.89, 58.37), iconImage: 'pin'),
  SymbolOptions(geometry: LatLng(37.90, 58.38), iconImage: 'pin'),
]);
```

### `updateSymbol`

```dart
await controller.updateSymbol(symbol, SymbolOptions(
  geometry: LatLng(37.91, 58.39),
  iconSize: 0.2,
));
```

### `getSymbolLatLng`

```dart
final latLng = controller.getSymbolLatLng(symbol);
```

### `removeSymbol` / `removeSymbols` / `clearSymbols`

```dart
await controller.removeSymbol(symbol);
await controller.removeSymbols([symbol1, symbol2]);
await controller.clearSymbols(); // удалить все
```

### Обработка тапов по символам

```dart
controller.onSymbolTapped.add((symbol) {
  print('Тапнули по символу: ${symbol.data}');
});
```

---

## 7. Линии (Lines)

### `addLine` / `addLines`

```dart
final line = await controller.addLine(
  LineOptions(
    geometry: [
      LatLng(37.89, 58.37),
      LatLng(37.90, 58.38),
      LatLng(37.91, 58.39),
    ],
    lineColor: '#2196F3',
    lineWidth: 3.0,
    lineOpacity: 0.8,
    draggable: false,
  ),
);
```

### `updateLine` / `getLineLatLngs` / `removeLine` / `removeLines` / `clearLines`

```dart
await controller.updateLine(line, LineOptions(lineColor: '#FF0000'));
final points = controller.getLineLatLngs(line);
await controller.removeLine(line);
await controller.clearLines();
```

---

## 8. Круги (Circles)

### `addCircle` / `addCircles`

```dart
final circle = await controller.addCircle(
  CircleOptions(
    geometry: LatLng(37.89, 58.37),
    circleRadius: 30,
    circleColor: '#FF5722',
    circleOpacity: 0.5,
    circleStrokeWidth: 2,
    circleStrokeColor: '#FFFFFF',
    draggable: true,
  ),
);
```

### `updateCircle` / `getCircleLatLng` / `removeCircle` / `removeCircles` / `clearCircles`

```dart
await controller.updateCircle(circle, CircleOptions(circleRadius: 50));
final pos = controller.getCircleLatLng(circle);
await controller.removeCircle(circle);
await controller.clearCircles();
```

---

## 9. Заливки (Fills)

### `addFill` / `addFills`

```dart
final fill = await controller.addFill(
  FillOptions(
    geometry: [
      [
        LatLng(37.88, 58.35),
        LatLng(37.88, 58.40),
        LatLng(37.92, 58.40),
        LatLng(37.92, 58.35),
      ]
    ],
    fillColor: '#4CAF50',
    fillOpacity: 0.4,
    fillOutlineColor: '#388E3C',
    draggable: false,
  ),
);
```

### `updateFill` / `getFillLatLngs` / `removeFill` / `removeFills` / `clearFills`

```dart
await controller.updateFill(fill, FillOptions(fillColor: '#F44336'));
final coords = controller.getFillLatLngs(fill);
await controller.removeFill(fill);
await controller.clearFills();
```

---

## 10. Изображения

### `addImage`

Добавляет изображение в стиль карты для использования в символах.

```dart
Future<void> addImage(String name, Uint8List bytes, [bool sdf = false])
```

```dart
// Из ассетов
final byteData = await rootBundle.load('assets/icon.png');
await controller.addImage('my-icon', byteData.buffer.asUint8List());

// Из сети
final response = await http.get(Uri.parse('https://example.com/icon.png'));
await controller.addImage('remote-icon', response.bodyBytes);

// SDF-иконка (можно перекрашивать через iconColor)
await controller.addImage('sdf-icon', bytes, true);
```

> ⚠️ Вызывать **только после** `onStyleLoaded`. При смене стиля изображения нужно добавлять заново.

---

## 11. Запросы (Query)

### `queryRenderedFeatures`

Запрос видимых фич в точке экрана.

```dart
Future<List> queryRenderedFeatures(
  Point<double> point, List<String> layerIds, List<Object>? filter)
```

```dart
final features = await controller.queryRenderedFeatures(
  Point(100.0, 200.0),
  ['points-layer', 'zones-layer'],
  null,
);
for (final f in features) {
  print('Feature: ${f['properties']}');
}
```

### `queryRenderedFeaturesInRect`

Запрос видимых фич в прямоугольной области.

```dart
final features = await controller.queryRenderedFeaturesInRect(
  Rect.fromLTWH(50, 50, 200, 200),
  ['points-layer'],
  null,
);
```

### `querySourceFeatures`

Запрос **всех** фич источника (не только видимых).

```dart
final features = await controller.querySourceFeatures(
  'points-source',
  null,  // sourceLayerId (для vector tiles)
  null,  // filter
);
```

---

## 12. Координаты и экран

### `toScreenLocation` / `toScreenLocationBatch`

Конвертация `LatLng` → точку на экране.

```dart
final point = await controller.toScreenLocation(LatLng(37.89, 58.37));
print('x: ${point.x}, y: ${point.y}');

final points = await controller.toScreenLocationBatch([
  LatLng(37.89, 58.37),
  LatLng(37.90, 58.38),
]);
```

### `toLatLng`

Конвертация точки экрана → `LatLng`.

```dart
final latLng = await controller.toLatLng(Point(150, 300));
```

### `getMetersPerPixelAtLatitude`

```dart
final mpp = await controller.getMetersPerPixelAtLatitude(37.89);
print('Метров в пикселе: $mpp');
```

---

## 13. Стиль и язык

### `setStyle`

Загружает новый стиль карты. Поддерживает URL, путь к ассету, путь к файлу, JSON-строку (Android).

```dart
await controller.setStyle('https://demotiles.maplibre.org/style.json');
await controller.setStyle('assets/my_style.json');
```

### `getStyle`

```dart
final json = await controller.getStyle();
```

### `setMapLanguage`

Меняет язык подписей на карте (по стандарту OSM `name:xx`).

```dart
await controller.setMapLanguage('ru');  // русский
await controller.setMapLanguage('en');  // английский
```

### `matchMapLanguageWithDeviceDefault`

```dart
await controller.matchMapLanguageWithDeviceDefault();
```

### `setCustomHeaders` / `getCustomHeaders`

```dart
await controller.setCustomHeaders(
  {'Authorization': 'Bearer TOKEN'},
  ['https://tiles.example.com/*'],
);
final headers = await controller.getCustomHeaders();
```

---

## 14. Настройки символов

Глобальные настройки коллизий символов:

```dart
await controller.setSymbolIconAllowOverlap(true);       // иконки не скрываются при перекрытии
await controller.setSymbolIconIgnorePlacement(true);     // другие символы не скрываются иконками
await controller.setSymbolTextAllowOverlap(true);        // текст не скрывается при перекрытии
await controller.setSymbolTextIgnorePlacement(true);     // другие символы не скрываются текстом
```

---

## 15. Кэш и телеметрия

```dart
await controller.invalidateAmbientCache(); // пометить кэш как устаревший
await controller.clearAmbientCache();       // полностью очистить кэш

await controller.setTelemetryEnabled(false);
final enabled = await controller.getTelemetryEnabled();

await controller.setMaximumFps(30);
await controller.forceOnlineMode();
```

---

## 16. Свойства и коллбэки

### Свойства (getters)

| Свойство         | Тип               | Описание                 |
| ---------------- | ----------------- | ------------------------ |
| `symbols`        | `Set<Symbol>`     | Все добавленные символы  |
| `lines`          | `Set<Line>`       | Все добавленные линии    |
| `circles`        | `Set<Circle>`     | Все добавленные круги    |
| `fills`          | `Set<Fill>`       | Все добавленные заливки  |
| `isCameraMoving` | `bool`            | Камера в движении?       |
| `cameraPosition` | `CameraPosition?` | Текущая позиция камеры   |
| `isDisposed`     | `bool`            | Контроллер утилизирован? |

### Коллбэки конструктора

| Коллбэк                     | Тип                                     | Описание                     |
| --------------------------- | --------------------------------------- | ---------------------------- |
| `onStyleLoadedCallback`     | `void Function()`                       | Стиль загружен               |
| `onMapClick`                | `void Function(Point, LatLng)`          | Тап по карте                 |
| `onMapLongClick`            | `void Function(Point, LatLng)`          | Долгое нажатие               |
| `onCameraMove`              | `void Function(CameraPosition)`         | Камера двигается             |
| `onCameraIdle`              | `void Function()`                       | Камера остановилась          |
| `onMapIdle`                 | `void Function()`                       | Карта в idle                 |
| `onUserLocationUpdated`     | `void Function(UserLocation)`           | Обновление GPS               |
| `onCameraTrackingDismissed` | `void Function()`                       | Отслеживание камеры отменено |
| `onCameraTrackingChanged`   | `void Function(MyLocationTrackingMode)` | Режим отслеживания изменён   |

### Коллбэки аннотаций

```dart
controller.onSymbolTapped.add((Symbol s) => print('Symbol tapped'));
controller.onLineTapped.add((Line l) => print('Line tapped'));
controller.onCircleTapped.add((Circle c) => print('Circle tapped'));
controller.onFillTapped.add((Fill f) => print('Fill tapped'));
```

### Коллбэки фич (для GeoJSON layers)

```dart
// Тап по фиче из GeoJSON-слоя
controller.onFeatureTapped.add((point, latLng, id, layerId, annotation) {
  print('Feature $id в слое $layerId');
});

// Перетаскивание
controller.onFeatureDrag.add((point, origin, current, delta, id, annotation, eventType) {
  print('Drag: $eventType, id: $id');
});

// Hover (только web)
controller.onFeatureHover.add((point, latLng, id, annotation, eventType) {
  print('Hover: $eventType, id: $id');
});
```

---

### Web-специфичные методы

```dart
controller.resizeWebMap();       // проверяет и ресайзит если нужно
controller.forceResizeWebMap();  // ресайз без проверок
```

### Геолокация

```dart
final pos = await controller.requestMyLocationLatLng();
await controller.updateMyLocationTrackingMode(MyLocationTrackingMode.tracking);
```

### Content Insets

```dart
await controller.updateContentInsets(
  EdgeInsets.only(bottom: 200),
  true, // animated
);
```

### dispose

```dart
controller.dispose(); // вызывается автоматически при удалении виджета
```

---

> **Совет по `iconAnchor`:** допустимые значения: `center`, `top`, `bottom`, `left`, `right`, `top-left`, `top-right`, `bottom-left`, `bottom-right`.

> **⚠️ Порядок координат в GeoJSON:** всегда `[longitude, latitude]` (не `[lat, lng]`!). А в `LatLng` — наоборот: `LatLng(latitude, longitude)`.
