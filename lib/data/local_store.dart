import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_data.dart';

/// Error de lectura o escritura que la interfaz puede mostrar sin perder el
/// estado anterior.
class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

typedef DocumentsDirectoryProvider = Future<Directory> Function();

/// Persistencia local en JSON dentro de documentos de la aplicación.
///
/// Límite deliberado: hasta 500 servicios y 10 000 recibos, con un archivo de
/// hasta 5 MB. Si el alcance crece o se añade sincronización, corresponde
/// migrar a una base de datos en lugar de ampliar esta clase.
class LocalStore {
  LocalStore({DocumentsDirectoryProvider? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final DocumentsDirectoryProvider _documentsDirectory;

  static const String fileName = 'aldia.json';
  static const int maxFileBytes = 5 * 1024 * 1024;
  static const String folderName = 'AlDiaFlutter';

  Future<Directory> appDirectory() async {
    final base = await _documentsDirectory();
    return Directory('${base.path}${Platform.pathSeparator}$folderName');
  }

  Future<File> mainFile() async {
    final directory = await appDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<File> _temporaryFile() async {
    final directory = await appDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName.tmp');
  }

  /// Lee y valida el documento completo. Si no existe, devuelve un estado
  /// vacío; si existe y es inválido, conserva el archivo y lanza un error.
  Future<AppData> load() async {
    try {
      final file = await mainFile();
      if (!await file.exists()) return AppData.empty;
      final length = await file.length();
      if (length > maxFileBytes) {
        throw const StorageException(
          'El archivo de datos supera el tamaño admitido de 5 MB.',
        );
      }
      final text = await file.readAsString();
      Object? decoded;
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        throw const StorageException(
          'El archivo de datos está dañado y no se puede leer como JSON.',
        );
      }
      try {
        return AppData.fromJson(decoded);
      } on FormatException catch (error) {
        throw StorageException(
          'El archivo de datos no es válido: ${error.message}',
          error,
        );
      }
    } on StorageException {
      rethrow;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo leer el archivo de datos. Revisa los permisos del '
        'directorio de documentos.',
        error,
      );
    }
  }

  /// Valida y escribe en un archivo temporal hermano; solo después reemplaza
  /// el archivo principal. Un fallo deja intacto el documento anterior.
  Future<void> save(AppData data) async {
    final validated = AppData.fromJson(data.toJson());
    final directory = await appDirectory();
    File? temporary;
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      temporary = await _temporaryFile();
      if (await temporary.exists()) {
        if (await FileSystemEntity.isDirectory(temporary.path)) {
          throw const StorageException(
            'No se pudo preparar la escritura: la ruta temporal está ocupada.',
          );
        }
        await temporary.delete();
      }
      final encoder = const JsonEncoder.withIndent('  ');
      final raf = await temporary.open(mode: FileMode.write);
      try {
        await raf.writeString(encoder.convert(validated.toJson()));
        await raf.flush();
      } finally {
        await raf.close();
      }
      final file = await mainFile();
      await temporary.rename(file.path);
    } on StorageException {
      rethrow;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo guardar el archivo de datos. Se conservó la información '
        'anterior; puedes reintentar.',
        error,
      );
    } finally {
      if (temporary != null) {
        try {
          if (await temporary.exists() &&
              !await FileSystemEntity.isDirectory(temporary.path)) {
            await temporary.delete();
          }
        } on FileSystemException {
          // La limpieza del temporal no debe ocultar el resultado principal.
        }
      }
    }
  }

  /// Copia el archivo inválido antes de un reinicio explícito. Devuelve la
  /// ruta de la copia, o null si no había archivo principal.
  Future<String?> backupInvalid() async {
    final file = await mainFile();
    if (!await file.exists()) return null;
    final directory = await appDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final backup = File(
      '${directory.path}${Platform.pathSeparator}aldia.invalid-$stamp.json',
    );
    try {
      await file.copy(backup.path);
      return backup.path;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo conservar una copia del archivo inválido; no se '
        'reiniciaron los datos.',
        error,
      );
    }
  }

  /// Conserva una copia y elimina el archivo principal. Solo debe usarse tras
  /// una confirmación explícita de la persona usuaria.
  Future<String?> resetAfterError() async {
    final backup = await backupInvalid();
    final file = await mainFile();
    try {
      if (await file.exists()) await file.delete();
      final temp = await _temporaryFile();
      if (await temp.exists() &&
          !await FileSystemEntity.isDirectory(temp.path)) {
        await temp.delete();
      }
      return backup;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo reiniciar el archivo de datos.',
        error,
      );
    }
  }
}
