import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../conditional/conditional.dart';
import '../models/preview_image.dart';

class ImageGallery extends StatelessWidget {
  const ImageGallery({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.images,
    required this.onClosePressed,
    this.options = const ImageGalleryOptions(),
    required this.pageController,
  });

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })? imageProviderBuilder;

  /// Images to show in the gallery.
  final List<PreviewImage> images;

  /// Triggered when the gallery is swiped down or closed via the icon.
  final VoidCallback onClosePressed;

  /// Customisation options for the gallery.
  final ImageGalleryOptions options;

  /// Page controller for the image pages.
  final PageController pageController;

  Widget _imageGalleryLoadingBuilder(ImageChunkEvent? event) {
    double? progress = (event == null || event.expectedTotalBytes == null)
        ? null // 让 CircularProgressIndicator 进入无限旋转模式
        : event.cumulativeBytesLoaded / event.expectedTotalBytes!;

    return Container(
      color: Colors.black, // 设置黑色背景
      alignment: Alignment.center,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: progress, // 允许 null，进入无限旋转
          strokeWidth: 3,
          backgroundColor: Colors.white.withOpacity(0.3), // 进度条背景色
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // 进度条颜色
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dismissible(
        key: const Key('photo_view_gallery'),
        direction: DismissDirection.down,
        onDismissed: (direction) => onClosePressed(),
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              builder: (BuildContext context, int index) => PhotoViewGalleryPageOptions(
                imageProvider: imageProviderBuilder != null
                    ? imageProviderBuilder!(
                        uri: images[index].uri,
                        imageHeaders: imageHeaders,
                        conditional: Conditional(),
                      )
                    : Conditional().getProvider(
                        images[index].uri,
                        headers: imageHeaders,
                      ),
                minScale: options.minScale,
                maxScale: options.maxScale,
              ),
              itemCount: images.length,
              loadingBuilder: (context, event) => _imageGalleryLoadingBuilder(event),
              pageController: pageController,
              scrollPhysics: const ClampingScrollPhysics(),
            ),
            Positioned.directional(
              end: 16,
              textDirection: Directionality.of(context),
              top: 56,
              child: CloseButton(
                color: Colors.white,
                onPressed: onClosePressed,
              ),
            ),
          ],
        ),
      );
}

class ImageGalleryOptions {
  const ImageGalleryOptions({
    this.maxScale,
    this.minScale,
  });

  /// See [PhotoViewGalleryPageOptions.maxScale].
  final dynamic maxScale;

  /// See [PhotoViewGalleryPageOptions.minScale].
  final dynamic minScale;
}
