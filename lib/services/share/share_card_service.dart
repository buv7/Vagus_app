import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/design_tokens.dart';
import '../../services/billing/plan_access_manager.dart';

/// Enum for share card templates
enum ShareTemplate {
  minimal,
  splitCompare,
  gridStats,
  ringFocus,
  badgeFlex,
}

/// Data model for share cards
class ShareDataModel {
  final String title;
  final String subtitle;
  final Map<String, dynamic> metrics;
  final List<String>? imagePaths;
  final DateTime? date;
  final String? handle;
  final bool showCoach;

  const ShareDataModel({
    required this.title,
    required this.subtitle,
    required this.metrics,
    this.imagePaths,
    this.date,
    this.handle,
    this.showCoach = true,
  });
}

/// Share asset result
class ShareAsset {
  final String path;
  final bool isVideo;
  final String? caption;

  const ShareAsset({
    required this.path,
    this.isVideo = false,
    this.caption,
  });
}

/// Service for building social share cards
class ShareCardService {
  static final ShareCardService _instance = ShareCardService._internal();
  factory ShareCardService() => _instance;
  ShareCardService._internal();

  final PlanAccessManager _planAccessManager = PlanAccessManager.instance;

  /// Build a story format share card
  Future<ShareAsset> buildStory(
    ShareTemplate template,
    ShareDataModel data, {
    bool minimalWatermark = false,
  }) async {
    final isPro = await _planAccessManager.isProUser();
    final watermark = minimalWatermark && isPro ? 'minimal' : 'standard';
    
    final widget = _buildStoryWidget(template, data, watermark);
    final path = await _renderToPng(widget, 'story_${template.name}');
    
    return ShareAsset(
      path: path,
      caption: _generateCaption(data),
    );
  }

  /// Build a feed format share card
  Future<ShareAsset> buildFeed(
    ShareTemplate template,
    ShareDataModel data, {
    bool minimalWatermark = false,
  }) async {
    final isPro = await _planAccessManager.isProUser();
    final watermark = minimalWatermark && isPro ? 'minimal' : 'standard';
    
    final widget = _buildFeedWidget(template, data, watermark);
    final path = await _renderToPng(widget, 'feed_${template.name}');
    
    return ShareAsset(
      path: path,
      caption: _generateCaption(data),
    );
  }

  Widget _buildStoryWidget(ShareTemplate template, ShareDataModel data, String watermark) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.ink900,
            DesignTokens.ink700,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Main content based on template
          _buildTemplateContent(template, data),
          
          // Watermark
          Positioned(
            bottom: 40,
            right: 40,
            child: _buildWatermark(watermark),
          ),
          
          // Handle (if enabled)
          if (data.handle != null && data.showCoach)
            Positioned(
              top: 60,
              left: 40,
              child: _buildHandle(data.handle!),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedWidget(ShareTemplate template, ShareDataModel data, String watermark) {
    return Container(
      width: 1080,
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.ink50,
            DesignTokens.ink100,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Main content based on template
          _buildTemplateContent(template, data),
          
          // Watermark
          Positioned(
            bottom: 30,
            right: 30,
            child: _buildWatermark(watermark),
          ),
          
          // Handle (if enabled)
          if (data.handle != null && data.showCoach)
            Positioned(
              top: 40,
              left: 40,
              child: _buildHandle(data.handle!),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateContent(ShareTemplate template, ShareDataModel data) {
    switch (template) {
      case ShareTemplate.minimal:
        return _buildMinimalTemplate(data);
      case ShareTemplate.splitCompare:
        return _buildSplitCompareTemplate(data);
      case ShareTemplate.gridStats:
        return _buildGridStatsTemplate(data);
      case ShareTemplate.ringFocus:
        return _buildRingFocusTemplate(data);
      case ShareTemplate.badgeFlex:
        return _buildBadgeFlexTemplate(data);
    }
  }

  Widget _buildMinimalTemplate(ShareDataModel data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            style: DesignTokens.displayLarge.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
          if (data.metrics.isNotEmpty) ...[
            const SizedBox(height: 40),
            _buildMetricsRow(data.metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitCompareTemplate(ShareDataModel data) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Text(
            data.title,
            style: DesignTokens.titleLarge.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.ink700.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Before',
                        style: DesignTokens.titleLarge.copyWith(
                          color: DesignTokens.ink500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'After',
                        style: DesignTokens.titleLarge.copyWith(
                          color: DesignTokens.success,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridStatsTemplate(ShareDataModel data) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Text(
            data.title,
            style: DesignTokens.titleLarge.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: data.metrics.length,
              itemBuilder: (context, index) {
                final entry = data.metrics.entries.elementAt(index);
                return _buildMetricCard(entry.key, entry.value.toString());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingFocusTemplate(ShareDataModel data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  DesignTokens.blue600.withValues(alpha: 0.8),
                  DesignTokens.blue600,
                ],
              ),
            ),
            child: Center(
              child: Text(
                data.metrics.values.first.toString(),
                style: DesignTokens.displayLarge.copyWith(
                  color: DesignTokens.ink50,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeFlexTemplate(ShareDataModel data) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Text(
            data.title,
            style: DesignTokens.titleLarge.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: data.metrics.entries.map((entry) {
                return _buildBadge(entry.key, entry.value.toString());
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: metrics.entries.map((entry) {
        return Column(
          children: [
            Text(
              entry.value.toString(),
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.blue600,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.key,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.ink700.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.blue600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.blue600.withValues(alpha: 0.8),
            DesignTokens.blue600,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: DesignTokens.titleLarge.copyWith(
              color: DesignTokens.ink50,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermark(String type) {
    final opacity = type == 'minimal' ? 0.3 : 0.6;
    final fontSize = type == 'minimal' ? 12.0 : 16.0;
    
    return Opacity(
      opacity: opacity,
      child: Text(
        'VAGUS',
        style: TextStyle(
          color: DesignTokens.ink50,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHandle(String handle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.ink700.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '@$handle',
        style: DesignTokens.bodyMedium.copyWith(
          color: DesignTokens.ink500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _generateCaption(ShareDataModel data) {
    final caption = StringBuffer();
    caption.write(data.title);
    
    if (data.subtitle.isNotEmpty) {
      caption.write('\n${data.subtitle}');
    }
    
    if (data.metrics.isNotEmpty) {
      caption.write('\n\n');
      data.metrics.forEach((key, value) {
        caption.write('$key: $value\n');
      });
    }
    
    caption.write('\n#VAGUS #Fitness #Progress');
    
    return caption.toString();
  }

  Future<String> _renderToPng(Widget widget, String filename) async {
    // For now, return a placeholder path since rendering to PNG requires
    // a proper BuildContext and rendering pipeline
    // TODO: Implement proper PNG rendering when needed
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$filename.png';
    
    // Create a placeholder file for now
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    
    return path;
  }
}
