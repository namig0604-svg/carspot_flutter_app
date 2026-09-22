import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Компактный виджет выбора фото вместо ручного ввода URL: показывает
/// превью (текущий URL, либо локально выбранный файл пока идёт загрузка),
/// по тапу предлагает "Галерея"/"Камера", грузит выбранный файл через
/// ApiService.uploadImage('/api/photos/upload-file', ...) и записывает
/// вернувшийся URL прямо в переданный [controller] — остальной код формы
/// (submit и т.д.) продолжает работать без изменений.
class ImageUrlPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? token;
  final bool circular;
  final double width;
  final double height;
  final IconData placeholderIcon;
  final String galleryLabel;
  final String cameraLabel;
  final String Function(Object error) errorTextBuilder;
  final VoidCallback? onChanged;

  const ImageUrlPickerField({
    Key? key,
    required this.controller,
    required this.token,
    required this.galleryLabel,
    required this.cameraLabel,
    required this.errorTextBuilder,
    this.circular = false,
    this.width = double.infinity,
    this.height = 150,
    this.placeholderIcon = Icons.add_a_photo_outlined,
    this.onChanged,
  }) : super(key: key);

  @override
  State<ImageUrlPickerField> createState() => _ImageUrlPickerFieldState();
}

class _ImageUrlPickerFieldState extends State<ImageUrlPickerField> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  Uint8List? _localPreview;

  Future<void> _chooseSource() async {
    if (_isUploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(widget.galleryLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(widget.cameraLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndUpload(source);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.errorTextBuilder(e))));
      }
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _localPreview = bytes;
    });
    try {
      final response = await ApiService.uploadImage(
        '/api/photos/upload-file',
        bytes,
        picked.name.isNotEmpty ? picked.name : 'photo.jpg',
        token: widget.token,
      );
      final url = response['url'] as String;
      widget.controller.text = url;
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.errorTextBuilder(e))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    final borderRadius = widget.circular ? BorderRadius.circular(1000) : BorderRadius.circular(12);

    Widget content;
    if (_localPreview != null) {
      content = Image.memory(_localPreview!, fit: BoxFit.cover, width: widget.width, height: widget.height);
    } else if (url.isNotEmpty) {
      content = Image.network(
        url,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: Icon(widget.placeholderIcon, size: 32, color: Colors.grey),
        ),
      );
    } else {
      content = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(widget.placeholderIcon, size: 32, color: Colors.grey),
      );
    }

    return GestureDetector(
      onTap: _chooseSource,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (_isUploading)
                Container(
                  color: Colors.black38,
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                )
              else
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
