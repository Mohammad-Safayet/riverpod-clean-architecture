import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';

/// THE way to show a remote image: disk/memory cached, with one placeholder and
/// one error look for the whole app. Change them here, every screen follows.
///
/// Null, empty or non-http URLs render the error look without touching the network.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  static bool isValidUrl(String? url) =>
      url != null && (url.startsWith('http://') || url.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final image = isValidUrl(url)
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, _) => _Box(width: width, height: height),
            errorWidget: (context, _, _) => _Box(width: width, height: height, broken: true),
          )
        : _Box(width: width, height: height, broken: true);
    return borderRadius == 0
        ? image
        : ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: image);
  }
}

/// Circular user/profile picture with an initial as the fallback.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.url, required this.name, this.size = 40});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.divider,
      foregroundImage: AppNetworkImage.isValidUrl(url) ? CachedNetworkImageProvider(url!) : null,
      child: Text(initial, style: context.textStyles.title.copyWith(color: colors.textSecondary)),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({this.width, this.height, this.broken = false});

  final double? width;
  final double? height;
  final bool broken;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: context.colors.divider,
      child: broken
          ? Icon(Icons.image_not_supported_outlined, color: context.colors.textSecondary)
          : null,
    ),
  );
}
