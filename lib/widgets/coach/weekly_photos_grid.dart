import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/coach/weekly_review_service.dart';

class WeeklyPhotosGrid extends StatelessWidget {
  final List<ProgressPhoto> photos;
  const WeeklyPhotosGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sorted = [...photos]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final gridCount = sorted.length == 1 ? 1 : (sorted.length == 2 ? 2 : 2);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check-in Photos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3/4,
            ),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) {
              final p = sorted[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                    return Scaffold(
                      backgroundColor: Colors.black,
                      body: SafeArea(
                        child: Stack(
                          children: [
                            PhotoViewGallery.builder(
                              itemCount: sorted.length,
                              builder: (c, index) {
                                return PhotoViewGalleryPageOptions(
                                  imageProvider: NetworkImage(sorted[index].url),
                                  heroAttributes: PhotoViewHeroAttributes(tag: sorted[index].url),
                                );
                              },
                              backgroundDecoration: const BoxDecoration(color: Colors.black),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }));
                },
                child: Hero(
                  tag: p.url,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(p.url, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
