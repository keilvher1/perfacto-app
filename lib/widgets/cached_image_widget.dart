import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 통일된 이미지 캐싱 위젯
///
/// 모든 네트워크 이미지를 캐싱하여 성능 향상
/// - 메모리 캐시: 빠른 재표시
/// - 디스크 캐시: 오프라인 지원
/// - 자동 리사이징: 메모리 최적화
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? 800, // 기본 800px (메모리 최적화)
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: 1000, // 디스크 캐시 최대 1000px
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4E8AD9),
                    strokeWidth: 2,
                  ),
                ),
              ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
    );
  }
}

/// 원형 프로필 이미지 (사용자 프로필용)
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;

  const CachedCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius * 1.2,
          color: Colors.grey[600],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: imageProvider,
      ),
      memCacheWidth: (radius * 2 * 2).toInt(), // 2x for retina
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF4E8AD9),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: Icon(
          Icons.person,
          size: radius * 1.2,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
