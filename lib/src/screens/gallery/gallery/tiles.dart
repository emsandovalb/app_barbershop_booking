part of '../gallery_page.dart';

class _MasonryGalleryGrid extends StatelessWidget {
  final List<_GalleryItem> items;
  final ValueChanged<_GalleryItem> onItemTap;

  const _MasonryGalleryGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return BarbershopPremiumCard(
        padding: const EdgeInsets.all(18),
        radius: 24,
        child: Text(
          tr('gallery_empty_category'),
          style: TextStyle(color: Colors.white.withValues(alpha: .72)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        final columnItems = List.generate(columns, (_) => <_GalleryItem>[]);
        for (var index = 0; index < items.length; index++) {
          columnItems[index % columns].add(items[index]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var columnIndex = 0; columnIndex < columns; columnIndex++) ...[
              if (columnIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (
                      var itemIndex = 0;
                      itemIndex < columnItems[columnIndex].length;
                      itemIndex++
                    ) ...[
                      _GalleryTile(
                        item: columnItems[columnIndex][itemIndex],
                        onTap: () =>
                            onItemTap(columnItems[columnIndex][itemIndex]),
                      ),
                      if (itemIndex != columnItems[columnIndex].length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GalleryTile extends StatefulWidget {
  final _GalleryItem item;
  final VoidCallback onTap;

  const _GalleryTile({required this.item, required this.onTap});

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedScale(
      scale: _pressed ? .98 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: Container(
          height: 178 * item.heightFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF14100E),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
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
                      Colors.black.withValues(alpha: .66),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: PremiumBadge(label: item.tag, compact: true),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatefulWidget {
  final _GalleryItem item;
  final VoidCallback onTap;

  const _FeaturedCard({required this.item, required this.onTap});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: BarbershopPremiumCard(
          padding: EdgeInsets.zero,
          radius: 28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
                        Colors.black.withValues(alpha: .72),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: PremiumBadge(label: item.tag),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .76),
                          height: 1.35,
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
    );
  }
}
