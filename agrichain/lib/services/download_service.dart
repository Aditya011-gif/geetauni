import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
// Platform-specific file saving helpers
import 'file_saver_web.dart' if (dart.library.io) 'file_saver_io.dart';

// Enums and Data Classes for download system
enum DownloadStatus { ready, downloading, completed, error }

class DocumentInfo {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final IconData icon;
  final Color color;
  final String estimatedSize;
  String? actualSize;
  final Uint8List? contentBytes;

  DocumentInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.icon,
    required this.color,
    required this.estimatedSize,
    this.actualSize,
    this.contentBytes,
  });
}

class DownloadService {
  static const String _csrfToken = 'agrichain_download_token_2024';

  static const List<String> _allowedExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
  ];

  static const Map<String, String> _expectedHashes = {
    'AgriChain_Crop_Sale_Agreement.pdf': '',
    'AgriChain_Loan_Agreement.pdf': '',
  };

  Future<DownloadResult> downloadDocument(
    DocumentInfo document, {
    required Function(double) onProgress,
  }) async {
    try {
      if (!_validateCSRFToken()) {
        return DownloadResult(
          success: false,
          errorMessage: 'Security validation failed',
        );
      }
      if (!_validateFilePath(document.filePath)) {
        return DownloadResult(
          success: false,
          errorMessage: 'Invalid file path',
        );
      }
      if (!_validateFileExtension(document.fileName)) {
        return DownloadResult(
          success: false,
          errorMessage: 'File type not allowed',
        );
      }

      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        return DownloadResult(
          success: false,
          errorMessage: 'Storage permission denied',
        );
      }

      if (document.id == 'smart_contract') {
        return await _downloadSmartContractDoc(document, onProgress);
      } else {
        return await _downloadPDFFile(document, onProgress);
      }
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download failed: ${e.toString()}',
      );
    }
  }

  bool _validateCSRFToken() => _csrfToken.isNotEmpty;

  bool _validateFilePath(String filePath) {
    if (kIsWeb) return true;
    if (filePath.isEmpty) return false;
    if (filePath.contains('..') ||
        filePath.contains('~') ||
        filePath.startsWith('/etc') ||
        filePath.startsWith('/root') ||
        filePath.contains('\\..\\') ||
        filePath.contains('/../')) {
      return false;
    }
    final allowedPaths = [
      r'c:\geeta uni\geeta hack',
      r'c:\Users\adity\Downloads\geetauni',
    ];
    return allowedPaths.any(
      (p) => filePath.toLowerCase().startsWith(p.toLowerCase()),
    );
  }

  bool _validateFileExtension(String fileName) {
    final ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return _allowedExtensions.contains(ext);
  }

  Future<bool> _checkStoragePermission() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  Future<DownloadResult> _downloadPDFFile(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      await _simulateDownloadProgress(onProgress);
      Uint8List pdfContent;
      if (document.contentBytes != null) {
        pdfContent = document.contentBytes!;
      } else if (document.filePath.isNotEmpty) {
        try {
          final sourceFile = File(document.filePath);
          if (await sourceFile.exists()) {
            pdfContent = await sourceFile.readAsBytes();
          } else {
            pdfContent = _generateSamplePDFContent(document);
          }
        } catch (_) {
          pdfContent = _generateSamplePDFContent(document);
        }
      } else {
        pdfContent = _generateSamplePDFContent(document);
      }

      if (kIsWeb) {
        await FileSaverHelper().saveBytes(
          pdfContent,
          document.fileName,
          'application/pdf',
        );
        return DownloadResult(
          success: true,
          filePath: document.fileName,
          fileSize: pdfContent.length,
        );
      }

      final downloadDir = await _getDownloadDirectory();
      final targetFile = File('${downloadDir.path}/${document.fileName}');
      await targetFile.writeAsBytes(pdfContent);

      return DownloadResult(
        success: true,
        filePath: targetFile.path,
        fileSize: pdfContent.length,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download error: ${e.toString()}',
      );
    }
  }

  Uint8List _generateSamplePDFContent(DocumentInfo document) {
    final content =
        '%PDF-1.4\n1 0 obj\n<</Type /Catalog /Pages 2 0 R>>\nendobj\n%%EOF\n';
    return Uint8List.fromList(utf8.encode(content));
  }

  String _calculateFileHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<DownloadResult> _downloadSmartContractDoc(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      final contractContent =
          '# AgriChain Smart Contract Documentation\nGenerated: ${DateTime.now().toIso8601String()}\n';
      await _simulateDownloadProgress(onProgress);
      final bytes = Uint8List.fromList(utf8.encode(contractContent));

      if (kIsWeb) {
        await FileSaverHelper().saveBytes(
          bytes,
          document.fileName,
          'application/pdf',
        );
        return DownloadResult(
          success: true,
          filePath: document.fileName,
          fileSize: bytes.length,
        );
      }

      final downloadDir = await _getDownloadDirectory();
      final targetFile = File('${downloadDir.path}/${document.fileName}');
      await targetFile.writeAsBytes(bytes);
      return DownloadResult(
        success: true,
        filePath: targetFile.path,
        fileSize: bytes.length,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Smart contract generation failed: ${e.toString()}',
      );
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (kIsWeb) return await getApplicationDocumentsDirectory();
    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } catch (e) {
        // Fall back
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _simulateDownloadProgress(Function(double) onProgress) async {
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      onProgress(i / 100.0);
    }
  }
}

class DownloadResult {
  final bool success;
  final String? errorMessage;
  final String? filePath;
  final int? fileSize;

  DownloadResult({
    required this.success,
    this.errorMessage,
    this.filePath,
    this.fileSize,
  });
}
