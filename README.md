# Photo Organizer Suite

Suite de scripts para organizar colecciones de fotos y vídeos de forma profesional, basándose en modelo de cámara, fecha de captura, archivos RAW y detección de duplicados. Permite crear y mantener una base de datos de medios sin ensayo y error.

## Estructura de carpetas

```text
/
├── CAMERAS/                    Carpeta raíz con tus archivos
│   ├── <Modelo1>/              Carpetas creadas manualmente por modelo de cámara
│   │   ├── foto1.JPG
│   │   ├── 2024.05/            Subcarpetas mensuales (generadas por date_sort)
│   │   │   ├── Tema1/
│   │   │   │   ├── imagen.JPG
│   │   │   │   └── RAW/        Subcarpeta RAW (generada por raw_sort)
│   │   └── …
│   ├── <Modelo2>/
│   └── PRIVATE/                Carpeta destino para directorios marcados con “(X)”
└── scripts/                    Carpeta con los scripts de la suite
    ├── scan_exif_v1_estable.PY
    ├── model_sort_v2_estable.PY
    ├── date_sort_v1.2_estable.PY
    ├── raw_sort_v1_estable.PY
    ├── dup_search_v2.4_estable_tested.PY
    ├── copiar_private_estable.py
    └── stats_developing.py     (experimental, uso no recomendado)
```

## Requisitos

* Python 3.6 o superior
* [ExifTool](https://exiftool.org/) disponible en el `PATH`
* Paquetes Python:

  ```bash
  pip install fpdf pillow
  ```

## Guía de uso

1. **Preparar las fotos**
   Extrae las imágenes y vídeos de la tarjeta SD a `CAMERAS/`, sin crear subcarpetas adicionales.

2. **Detectar modelos y extensiones**

   ```bash
   python3 scripts/scan_exif_v1_estable.PY
   ```

   * Genera en `logs/` un log y un resumen de los modelos EXIF y extensiones únicas.

3. **Clasificar por modelo**

   * Edita `MODEL_TO_FOLDER` en `model_sort_v2_estable.PY` para mapear cada cadena EXIF a la carpeta correspondiente en `CAMERAS/`.

   ```bash
   python3 scripts/model_sort_v2_estable.PY
   ```

   * Registra errores por EXIF no mapeado, carpetas inexistentes o duplicados.

4. **Ordenar por fecha de captura**

   ```bash
   python3 scripts/date_sort_v1.2_estable.PY
   ```

   * Solicita selección de modelos.
   * Crea subcarpetas `YYYY.MM` y mueve fotos sueltas según EXIF o timestamps.
   * Ajusta fotos del día 1 con hora < 08:00 al mes anterior.
   * Omite y registra duplicados (mismo nombre en destino).
   * Genera log (`logs/`) y PDF (`pdf/`).

5. **Agrupar archivos RAW**

   ```bash
   python3 scripts/raw_sort_v1_estable.PY
   ```

   * Solicita selección de modelos.
   * Dentro de cada tema y subtema, crea `RAW/` y mueve los `.cr2` y `.arw` sueltos.
   * Omite y registra si no hay archivos RAW o si hay errores.

6. **Detectar duplicados exactos (SHA256)**

   ```bash
   python3 scripts/dup_search_v2.4_estable_tested.PY
   ```

   * Ignora `CAMERAS/PRIVATE/`.
   * Para cada modelo, agrupa por nombre+extensión.
   * Solo para nombres repetidos calcula SHA256 y registra las rutas con hash idéntico.

7. **Copiar carpetas marcadas “(X)”**

   ```bash
   python3 scripts/copiar_private_estable.py
   ```

   * Crea `CAMERAS/PRIVATE/` si hace falta.
   * Copia cualquier directorio con nombre que contenga `(X)`, preservando la jerarquía.
   * Omite destinos ya existentes (no elimina ni sobrescribe).

8. **Estadísticas (experimental)**

   ```bash
   python3 scripts/stats_developing.py
   ```

   * Genera gráficos y PDF con resumen estadístico.
   * Versión temprana, uso no recomendado.

## Flujo de trabajo recomendado

1. Ejecutar **scan\_exif** para identificar modelos.
2. Ajustar `MODEL_TO_FOLDER` y ejecutar **model\_sort**.
3. Ejecutar **date\_sort** para estructura mensual.
4. Ejecutar **raw\_sort** para agrupar RAW.
5. Ejecutar **dup\_search** para eliminar duplicados exactos.
6. Ejecutar **copiar\_private** para extraer carpetas marcadas.
7. (Opcional) Ejecutar **stats\_developing** para generar estadísticas.

## Manejo de errores

* **ExifTool ausente**: scripts basados en EXIF fallarán.
* **Permiso denegado**: se registra y se omite el archivo o carpeta afectada.
* **EXIF no mapeado**: en model\_sort, el archivo permanece en origen.
* **Duplicados detectados**: no se sobrescribe, se omite y se lista en el log.
* **Destino inexistente**: se omite y se registra.
* **Sin carpetas mensuales**: date\_sort registra “sin cambios”.
