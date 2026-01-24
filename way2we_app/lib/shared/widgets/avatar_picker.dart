import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/theme/theme.dart';

/// Reusable avatar picker widget.
/// Used in both Onboarding and Profile Settings.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.onTap,
    this.size = 120,
  });

  /// The locally selected image file (XFile from image_picker).
  final XFile? imageFile;

  /// The current avatar URL from the server (displayed if no local file).
  final String? imageUrl;

  /// Callback when the avatar is tapped.
  final VoidCallback? onTap;

  /// Size of the avatar (width and height).
  final double size;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (imageFile != null) {
      imageProvider = kIsWeb
          ? NetworkImage(imageFile!.path)
          : FileImage(File(imageFile!.path));
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceMutedLight,
              border: Border.all(
                color: AppColors.borderSubtleLight,
                width: 2,
              ),
              boxShadow: AppShadows.card,
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageProvider == null
                ? Icon(
                    Icons.person_outline,
                    size: size * 0.4,
                    color: AppColors.textMutedLight,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: size * 0.15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
