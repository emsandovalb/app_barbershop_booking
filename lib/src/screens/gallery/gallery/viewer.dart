part of '../gallery_page.dart';

class _GalleryViewerPage extends StatelessWidget {
  final _GalleryItem item;

  const _GalleryViewerPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 0.82,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.asset.isNotEmpty)
                            Image.asset(item.asset, fit: BoxFit.cover)
                          else
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF151C31),
                                    Color(0xFF10172A),
                                    Color(0xFF0B1020),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: .84),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumBadge(label: item.tag),
                                const SizedBox(height: 14),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .78),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 14,
              child: _IconBubble(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool compact;

  const _SocialActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: filled ? theme.primary : const Color(0xFF171311),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled
                  ? theme.primary.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.black : theme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF171311),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _GalleryCategory {
  final String id;
  final String label;

  const _GalleryCategory({required this.id, required this.label});
}

class _GalleryItem {
  final String asset;
  final String title;
  final String description;
  final String category;
  final String tag;
  final double heightFactor;

  const _GalleryItem({
    required this.asset,
    required this.title,
    required this.description,
    required this.category,
    required this.tag,
    required this.heightFactor,
  });
}
