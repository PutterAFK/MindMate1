import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app_new/core/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? nickname;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                // Loading placeholder
                placeholder: (context, url) => Container(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                      constraints: BoxConstraints(
                        maxWidth: size * 0.4,
                        maxHeight: size * 0.4,
                      ),
                    ),
                  ),
                ),
                // Error fallback
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  // Fallback ถ้าไม่มีรูปหรือโหลดไม่ได้
  Widget _buildFallback() {
    if (nickname != null && nickname!.isNotEmpty) {
      // แสดงตัวอักษรแรกของ Nickname
      return Container(
        color: AppColors.primary,
        child: Center(
          child: Text(
            nickname![0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // แสดง Icon ถ้าไม่มี Nickname
    return Container(
      color: AppColors.primaryLight.withOpacity(0.3),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: size * 0.55,
      ),
    );
  }
}